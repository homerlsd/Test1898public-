public with sharing class SFDXDebugLogParser {

    private static final String typePattern = '/^[A-Z_]*$/';
    private static final String newlineRegex = '/\r?\n/';
    private static final String settingsPattern = '^\\d+\\.\\d+\\sAPEX_CODE,\\w+;APEX_PROFILING,.+$';
    
    private List<Object> logLines = new List<Object>();
    private Set<Object> truncated;
    private Set<Object> reasons = new Set<Object>();
    private Long cpuUsed = 0;
    public static DateTime lastTimestamp = null;
    private Long totalDuration = 0; // the maximum display value (in nano-seconds)
    private Boolean discontinuity = false;
    
    public SFDXDebugLogParser() {

    }

    public class LineIterator {
        private List<LogLine> lines;
        private Integer index;
        private Integer length;

        public LineIterator(List<LogLine> lines) {
            this.lines = lines;
            this.index = 0;
            this.length = lines.size();
        }
        public LogLine peek() {
            return this.index < this.length ? this.lines[this.index] : null;
        }
        public LogLine fetch() {
            return this.index < this.length ? this.lines[this.index++] : null;
        }
    }

    public virtual class LogLine {
        public Integer duration;
        public DateTime timestamp;
        public String type;
        public String logLine;
        public String text;
        public boolean acceptsText;
        public boolean declarative;
        public boolean isExit;
        public boolean isValid;
        public Integer lineNumber;
        public String namespace;
        public String group1;
        public Object value;
        public boolean hasValidSymbols;
        public String suffix;
        public String prefix;
        public boolean discontinuity;
        public Integer rowCount;

        public LogLine(String[] parts) {
            this.duration = 0;
            this.timestamp = null;
            this.type = '';
            this.logLine = '';
            this.text = '';
            this.acceptsText = false;
            this.declarative = false;
            this.isExit = false;
            this.isValid = true;
            this.lineNumber = null;
            this.namespace = null;
            this.group1 = null;
            this.value = null;
            this.hasValidSymbols = false;
            this.suffix = null;
            this.prefix = null;
            this.discontinuity = false;
            this.rowCount = null;
            if (parts != null) {
                this.type = parts[1];
                this.text = this.type;
                this.timestamp = parseTimestamp(parts[0]);
            }
        }

        private DateTime parseTimestamp(String timestamp) {
            // Implement the logic to parse the timestamp here
            return null;
        }

        // public virtual onEnd() {

        // }
    }
    
    public virtual class TimedNode extends LogLine {
        public Datetime timestamp { get; set; }
        public Datetime exitStamp { get; set; }
        public List<LogLine> children { get; set; }
        public Long selfTime { get; set; }
        public Integer totalDmlCount { get; set; }
        public Integer totalSoqlCount { get; set; }
        public Integer totalThrownCount { get; set; }
        public String timelineKey { get; set; }
        public String cpuType { get; set; }
        
        public TimedNode(List<String> parts, String timelineKey, String cpuType) {
            super(parts);
            this.timestamp = null;
            this.exitStamp = null;
            this.children = new List<LogLine>();
            this.selfTime = 0;
            this.totalDmlCount = 0;
            this.totalSoqlCount = 0;
            this.totalThrownCount = 0;
            this.timelineKey = timelineKey;
            this.cpuType = cpuType;
        }
        
        public String getBreadcrumbText() {
            String desc1 = this.text;
            Integer brace = desc1.indexOf('(');
            if (brace >= 0) {
                desc1 = desc1.substring(0, brace);
            }
            Integer dot = desc1.lastIndexOf('.');
            if (dot >= 0) {
                desc1 = desc1.substring(dot + 1);
            }
            return desc1;
        }
        
        public void addChild(LogLine line) {
            this.children.add(line);
        }
        
        public void recalculateDurations() {
            if (this.exitStamp != null) {
                this.selfTime = (Long)this.exitStamp.getTime() - this.timestamp.getTime();
                for (LogLine child : this.children) {
                    this.selfTime -= child.duration;
                }
            }
        }
    }

    public virtual class Method extends TimedNode {
        public Boolean isTruncated { get; set; }
        public List<String> exitTypes { get; set; }
        public String classes { get; set; }
        
        public Method(List<String> parts, List<String> exitTypes, String classes, String timelineKey, String cpuType) {
            super(parts, timelineKey, cpuType);
            this.isTruncated = false;
            this.exitTypes = exitTypes;
            this.classes = classes != null ? 'node ' + classes : 'node';
        }
        
        public Boolean isMatchingEnd(Detail endLine) {
            return (this.exitTypes.contains(endLine.type) &&
                    (endLine.lineNumber == null || this.lineNumber == null || endLine.lineNumber == this.lineNumber));
        }
        
        public Boolean endMethod(Detail endLine, LineIterator lineIter, List<Method> stack) {
            this.exitStamp = endLine.timestamp;
            // is this a 'good' end line?
            if (this.isMatchingEnd(endLine)) {
                discontinuity = false; // end stack unwinding
                lineIter.fetch(); // consume the line
                return true; // success
            } else if (discontinuity) {
                return true; // exception - unwind
            } else {
                for (Method m : stack) {
                    if (m.isMatchingEnd(endLine)) {
                        return true; // we match a method further down the stack - unwind
                    }
                }
                // we found an exit event on its own e.g a `METHOD_EXIT` without a `METHOD_ENTRY`
                //truncateLog(endLine.timestamp, 'Unexpected-Exit', 'unexpected');
                return false; // we have no matching method - ignore
            }
        }
        
        public void loadContent(LineIterator lineIter, List<Method> stack) {
            lastTimestamp = this.timestamp;
            if (this.exitTypes.size() > 0) {
                LogLine line;
                stack.add(this);
                while ((line = lineIter.peek()) != null) {
                    if (line.discontinuity) {
                        // discontinuities are stack unwinding (caused by Exceptions)
                        discontinuity = true; // start unwinding stack
                    }
                    if (line.isExit && this.endMethod((Detail)line, lineIter, stack)) {
                        // if (this.onEnd != null) {
                        //     // the method wants to see the exit line
                        //     this.onEnd((Detail)line, stack);
                        // }
                        break;
                    }
                    lineIter.fetch(); // it's a child - consume the line
                    lastTimestamp = line.timestamp;
                    if (line.isValid) {
                        // Implement the logic for handling different line types (children)
                        // For example, check the type and create appropriate child nodes
                        // and add them using this.addChild(line);
                    }
                    this.addChild(line);
                }
                if (line == null) {
                    // truncated method - terminate at the end of the log
                    this.exitStamp = lastTimestamp;
                    // we found an entry event on its own e.g a `METHOD_ENTRY` without a `METHOD_EXIT`
                    //truncateLog(lastTimestamp, 'Unexpected-End', 'unexpected');
                    this.isTruncated = true;
                }
                stack.remove(stack.size() - 1);
            }
            this.recalculateDurations();
        }
    }

    public class Detail extends LogLine {
        public Boolean hideable { get; set; }
        
        public Detail(List<String> parts) {
            super(parts);
            this.hideable = true;
        }
    }

    public class RootNode extends Method {
        public Datetime executionEndTime { get; set; }
        
        public RootNode() {
            super(null, null, null, null, null);
            this.text = 'Log Root';
            this.type = 'ROOT';
            this.timestamp = Datetime.newInstance(1970, 1, 1, 0, 0, 0); // Set timestamp to 0 (1970-01-01 00:00:00)
            this.exitStamp = Datetime.newInstance(1970, 1, 1, 0, 0, 0); // Set exitStamp to 0 (1970-01-01 00:00:00)
            this.executionEndTime = Datetime.newInstance(1970, 1, 1, 0, 0, 0); // Set executionEndTime to 0 (1970-01-01 00:00:00)
        }
        
        public void setEndTime() {
            // We do not just want to use the very last exitStamp because it could be CUMULATIVE_USAGE which is not really part of the code execution time but does have a later time.
            Datetime endTime;
            Integer len = this.children.size() - 1;
            for (Integer i = len; i >= 0; i--) {
                LogLine child = this.children[i];
                // If there is no duration on a node then it is not going to be shown on the timeline anyway
                if (child instanceof TimedNode){
                    TimedNode childTimeNode = (TimedNode)child;
                    if(childTimeNode.exitStamp != null) {
                        if (endTime == null) {
                            endTime = childTimeNode.exitStamp;
                        }
                        if (childTimeNode.duration != null && childTimeNode.duration > 0) {
                            this.executionEndTime = childTimeNode.exitStamp;
                            break;
                        }
                    }
                }
                if (endTime == null) {
                    endTime = child.timestamp;
                }
            }
            this.exitStamp = endTime != null ? endTime : Datetime.newInstance(1970, 1, 1, 0, 0, 0);
        }
    }

    public String parseObjectNamespace(String text) {
        Integer sep = text.indexOf('__');
        if (sep < 0) {
            return 'unmanaged';
        }
        return text.substring(0, sep);
    }
    
    public String parseVfNamespace(String text) {
        Integer sep = text.indexOf('__');
        if (sep < 0) {
            return 'unmanaged';
        }
        Integer firstSlash = text.indexOf('/');
        if (firstSlash < 0) {
            return 'unmanaged';
        }
        Integer secondSlash = text.indexOf('/', firstSlash + 1);
        if (secondSlash < 0) {
            return 'unmanaged';
        }
        return text.substring(secondSlash + 1, sep);
    }
    
    public Decimal parseTimestamp(String text) {
        Integer startIndex = text.indexOf('(') + 1;
        Integer endIndex = text.length() - 1;
        String timestamp = text.substring(startIndex, endIndex);
        if (!String.isBlank(timestamp)) {
            return Decimal.valueOf(timestamp);
        }
        throw new MyException('Unable to parse timestamp: \'' + text + '\'');
    }
    
    public Object parseLineNumber(String text) {
        Integer startIndex = 1;
        Integer endIndex = text.length() - 1;
        String lineNumberStr = text.substring(startIndex, endIndex);
        if (!String.isBlank(lineNumberStr)) {
            try {
                return Integer.valueOf(lineNumberStr);
            } catch (Exception ex) {
                return lineNumberStr;
            }
        }
        throw new MyException('Unable to parse line number: \'' + text + '\'');
    }
    
    public Integer parseRows(String text) {
        Integer startIndex = text.indexOf('Rows:') + 5;
        if (startIndex >= 5) {
            String rowCount = text.substring(startIndex);
            if (!String.isBlank(rowCount)) {
                return Integer.valueOf(rowCount);
            }
        }
        throw new MyException('Unable to parse row count: \'' + text + '\'');
    }

    public class MyException extends Exception {}

    /*public Object parseLine(String line, Object lastEntry) {
        Map<String, Type> lineTypeMap = new Map<String, Type> {
            // Add mapping of log types to Apex classes
            // For example: 'METHOD_ENTRY' => MethodEntryLine.class
            // 'METHOD_EXIT' => MethodExitLine.class, and so on
        };
        Pattern typePattern = Pattern.compile('^(INFO|DEBUG|ERROR|WARN|FATAL|FINE|FINER|FINEST|VERBO|AUDIT|CRITICAL|TRACE)\\|');
        // Define the settingsPattern if needed
        // Pattern settingsPattern = ...
        
        List<String> parts = line.split('\\|');
        String type = parts[1];
        Type metaCtor = lineTypeMap.get(type);
        
        if (metaCtor != null) {
            SObject entry = (SObject)metaCtor.newInstance();
            entry.put('LogLine', line);
            
            // Assuming lastEntry has the 'onAfter' method defined in the corresponding Apex class
            if (lastEntry != null && lastEntry.get('onAfter') != null) {
                ((Method)lastEntry).onAfter(entry);
            }
            
            return entry;
        }
        if (!typePattern.matcher(type).matches() && lastEntry != null && lastEntry.get('acceptsText') != null) {
            // wrapped text from the previous entry?
            String text = (String)lastEntry.get('text');
            lastEntry.put('text', text + ' | ' + line);
        } else if (type != null) {
            if (!type.equals('DUMMY')) {
                // Used by tests
                System.debug('Unknown log line: ' + type);
            }
        } else {
            if (lastEntry != null && line.startsWith('*** Skipped')) {
                // Assuming truncateLog function is defined elsewhere in the code
                //truncateLog((Decimal)lastEntry.get('timestamp'), 'Skipped-Lines', 'skip');
            } else if (lastEntry != null && line.contains('MAXIMUM DEBUG LOG SIZE REACHED')) {
                //truncateLog((Decimal)lastEntry.get('timestamp'), 'Max-Size-reached', 'skip');
            } else if (settingsPattern != null && settingsPattern.matcher(line).matches()) {
                // skip an unexpected settings line
            } else {
                System.debug('Bad log line: ' + line);
            }
        }
        return null;
    }

    public List<String> parseLog(String log) {
        Integer start = -1;
        Pattern pattern = Pattern.compile('^.*EXECUTION_STARTED.*$');
        Matcher matcher = pattern.matcher(log);
        if (matcher.find()) {
            start = matcher.start();
        }
        
        String[] rawLines = log.substring(start).split('\r?\n');
        
        List<String> logLines = new List<String>();
        List<String> truncated = new List<String>();
        Set<String> reasons = new Set<String>();
        Decimal cpuUsed = 0;
        Boolean discontinuity = false;
        String lastEntry = null;
        
        for (String line : rawLines) {
            if (!String.isBlank(line)) {
                // ignore blank lines
                String entry = parseLine(line, lastEntry);
                if (entry != null) {
                    logLines.add(entry);
                    lastEntry = entry;
                }
            }
        }
        
        return logLines;
    }*/
    
}