public with sharing class MIMEMessageService {

    public static final String BOUNDARY_START = '--';
    public static final String NEW_LINE = '\n';
    public static final String NEW_LINE_RETURN = '\r\n';
    public static final String RETURN_CARRET = '\r';
    public static final String TAB = '\t';
    public static final String SPACE = ' ';
    public static final String EMPTY_STRING = '';
    public static final String BOUNDARY_NAME = 'boundary=';
    public static final String HEADER_VALUE_SEPARATOR = ':';
    public static final String HEADER_SUBJECT = 'Subject';
    public static final String HEADER_DATE = 'Date';
    public static final String HEADER_FROM = 'From';
    public static final String HEADER_CONTENT_TYPE = 'Content-Type';
    public static final String HEADER_CONTENT_TYPE_TEXT = 'text/plain';
    public static final String HEADER_CONTENT_TYPE_HTML = 'text/html';
    public static final String HEADER_CONTENT_TYPE_MULTIPART = 'Content-Type: multipart';

    public String text = EMPTY_STRING;
    public String html = EMPTY_STRING;
    public String subject = EMPTY_STRING;
    public String dateHeader = EMPTY_STRING;
    public String fromHeader = EMPTY_STRING;
    public String fromAddress = EMPTY_STRING;
    public String fromName = EMPTY_STRING;

    public MIMEMessageService(String input) {
        parseText(input);
    }

    public class Header {
        public String name;
        public String value;
        
        public Header(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }

    public class MessagePart {
        public List<Header> headers;
        public List<String> content;
        
        public MessagePart() {
            headers = new List<Header>();
            content = new List<String>();
        }
    }

    public void parseText(String message) {
        // Normalize line endings to \n
        message = normalizeLineEndings(message);
        
        // Split the message into individual lines
        List<String> lines = message.split(NEW_LINE);
        
        // Find the boundary string
        String boundary = findBoundary(lines);
        
        // Parse the message parts
        List<MessagePart> parts = splitMessageParts(lines, boundary);
        
        // Extract text content from each part
        for (MessagePart part : parts) {
            String partContentType = findHeader(part.headers, HEADER_CONTENT_TYPE);
            if (partContentType.toLowerCase().startsWithIgnoreCase(HEADER_CONTENT_TYPE_TEXT)) {
                this.text += String.join(part.content, NEW_LINE);
            }
            else if (partContentType.toLowerCase().startsWithIgnoreCase(HEADER_CONTENT_TYPE_HTML)) {
                this.html += String.join(part.content, NEW_LINE);
                if(this.html.startsWith(NEW_LINE_RETURN)) {
                    this.html = this.html.removeStart(NEW_LINE_RETURN);
                }
                if(this.html.startsWith(NEW_LINE)) {
                    this.html = this.html.removeStart(NEW_LINE);
                }
            }
        }

        this.subject = findHeader(parts.get(0).headers, HEADER_SUBJECT);
        this.dateHeader = findHeader(parts.get(0).headers, HEADER_DATE);
        this.fromHeader = findHeader(parts.get(0).headers, HEADER_FROM);

        List<String> fromParts = this.fromHeader.split('<');
        this.fromName = fromParts.get(0).trim();
        this.fromAddress = fromParts.get(1).trim().removeEnd('>');
    }

    private String normalizeLineEndings(String message) {
        // Replace \r\n with \n
        message = message.replace(NEW_LINE_RETURN, NEW_LINE);
        // Replace \r with \n
        message = message.replace(RETURN_CARRET, NEW_LINE);
        return message;
    }

    private String findBoundary(List<String> lines) {
        for(Integer i = 0; i < lines.size(); i++) {
            String line = lines[i]; 
            if (line.startsWith(HEADER_CONTENT_TYPE_MULTIPART)) {
                // Extract the boundary string
                Integer boundaryIndex = line.indexOf(BOUNDARY_NAME);
                if(boundaryIndex == -1) {
                    line = lines[i+1];
                    boundaryIndex = line.indexOf(BOUNDARY_NAME);
                }
                if (boundaryIndex >= 0) {
                    String boundary = line.substring(boundaryIndex + 9);
                    boundary = boundary.trim();
                    boundary = boundary.substring(1, boundary.length() - 1);
                    return boundary;
                }
                break;
            }
        }
        return EMPTY_STRING;
    }

    private List<MessagePart> splitMessageParts(List<String> lines, String boundary) {
        List<MessagePart> parts = new List<MessagePart>();
        MessagePart currentPart = new MessagePart();
        Boolean isFullHeaderPart = true;
        Header currentHeader = null;

        if(boundary == EMPTY_STRING) {
            Boolean isBodyStart = false;

            for (String line : lines) {
                isBodyStart = isBodyStart || line == EMPTY_STRING;

                if(!isBodyStart) {
                    if(currentHeader != null && (line.startsWith(SPACE) || line.startsWith(TAB))) {
                        currentHeader.value += line;
                        currentPart.headers.set(currentPart.headers.size() - 1, currentHeader);
                    }
                    else {
                        currentHeader = getHeader(line);
                        currentPart.headers.add(currentHeader);
                    }
                }
                else {
                    currentPart.content.add(line);
                }
            }
            parts.add(currentPart);
        }
        else {
            for (String line : lines) {
                Boolean isBoundaryLine = (line.indexOf(BOUNDARY_START + boundary) != -1);
    
                if(isBoundaryLine) {
                    parts.add(currentPart);
                    currentPart = new MessagePart();
                    isFullHeaderPart = false;
                    continue;
                }
    
                if(isFullHeaderPart) {
                    if(currentHeader != null && (line.startsWith(SPACE) || line.startsWith(TAB))) {
                        currentHeader.value += line;
                        currentPart.headers.set(currentPart.headers.size() - 1, currentHeader);
                    }
                    else {
                        currentHeader = getHeader(line);
                        currentPart.headers.add(currentHeader);
                    }
                }
                else {
                    if(currentPart.headers.size() < 2) {
                        Header header = getHeader(line);
                        if(header != null) {
                            currentPart.headers.add(header);
                        }
                    }
                    else {
                        // must remove the =3D which is an incomplete escape code for "="
                        line = line.replace('=3D', '=');
                        currentPart.content.add(line);
                    }
                }
            }
        }
        
        return parts;
    }

    private Header getHeader(String line) {
        Header result;
        if(String.isNotBlank(line) && line.indexOf(HEADER_VALUE_SEPARATOR) != -1) {
            String[] headerParts = line.split(HEADER_VALUE_SEPARATOR, 2);
            if (headerParts.size() == 2) {
                String name = headerParts[0].trim();
                String value = headerParts[1].trim();
                result = new Header(name, value);
            }
        }
        return result;
    }
    
    private String findHeader(List<Header> headers, String name) {
        for (Header header : headers) {
            if (header.name.equalsIgnoreCase(name)) {
                return header.value;
            }
        }
        return EMPTY_STRING;
    }
}