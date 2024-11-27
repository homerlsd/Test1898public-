public class EMLParser {

    
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
        
        public static List<String> parseText(String message) {
            List<String> parsedText = new List<String>();
            
            // Normalize line endings to \n
            message = normalizeLineEndings(message);
            
            // Split the message into individual lines
            List<String> lines = message.split('\n');
            
            // Find the boundary string
            String boundary = findBoundary(lines);
            system.debug('---boundary--'+boundary);
            if (String.isBlank(boundary)) {
                return parsedText; // No boundary found
            }
            
            // Parse the message parts
            List<MessagePart> parts = splitMessageParts(lines, boundary);
            system.debug('---parts--'+json.serialize(parts));
            
            // Extract text content from each part
            for (MessagePart part : parts) {
                String partContentType = findHeader(part.headers, 'Content-Type');
                if (partContentType.toLowerCase() == 'text/html') {
                    List<String> textLines = extractTextContent(part.content);
                    parsedText.addAll(textLines);
                }
            }
            
            return parsedText;
        }
        
        private static String normalizeLineEndings(String message) {
            // Replace \r\n with \n
            message = message.replace('\r\n', '\n');
            // Replace \r with \n
            message = message.replace('\r', '\n');
            return message;
        }
        

        private static String findBoundary(List<String> lines) {
            //for (String line : lines) {
            for(Integer i = 0; i < lines.size(); i++) {
                String line = lines[i]; 
                //system.debug('---line--'+json.serialize(line));
                if (line.startsWith('Content-Type: multipart')) {
                    // Extract the boundary string
                    Integer boundaryIndex = line.indexOf('boundary=');
                    if(boundaryIndex == -1) {
                        line = lines[i+1];
                        boundaryIndex = line.indexOf('boundary=');
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
            return '';
        }
        // private static String findBoundary(List<String> lines) {
        //     for (String line : lines) {
        //         if (line.startsWith('Content-Type: multipart')) {
        //             // Extract the boundary string
        //             Integer boundaryIndex = line.indexOf('boundary=');
        //             if (boundaryIndex >= 0) {
        //                 String boundary = line.substring(boundaryIndex + 9);
        //                 return boundary.trim();
        //             }
        //             break;
        //         }
        //     }
        //     return '';
        // }
        
        private static List<MessagePart> splitMessageParts(List<String> lines, String boundary) {
            List<MessagePart> parts = new List<MessagePart>();
            MessagePart currentPart = new MessagePart();
            system.debug('-boundary='+JSON.serialize(boundary));
            system.debug('-boundary='+JSON.serialize(boundary.trim()));
            Boolean isFullHeaderPart = true;
            Header currentHeader = null;
            
            for (String line : lines) {
                system.debug('---line-'+json.serialize(line));
                Boolean isBoundaryLine = (line.indexOf('--' + boundary) != -1);

                if(isBoundaryLine) {
                    parts.add(currentPart);
                    currentPart = new MessagePart();
                    isFullHeaderPart = false;
                    continue;
                }

                if(isFullHeaderPart) {
                    if(currentHeader != null && (line.startsWith(' ') || line.startsWith('\t'))) {
                        currentHeader.value += line;
                        currentPart.headers.set(currentPart.headers.size() - 1, currentHeader);
                    }
                    else {
                        String[] headerParts = line.split(':', 2);
                        if (headerParts.size() == 2) {
                            String name = headerParts[0].trim();
                            String value = headerParts[1].trim();
                            currentHeader = new Header(name, value);
                            currentPart.headers.add(currentHeader);
                        }
                    }
                }
                else {
                    if(currentPart.headers.size() < 2) {
                        String[] headerParts = line.split(':', 2);
                        if (headerParts.size() == 2) {
                            String name = headerParts[0].trim();
                            String value = headerParts[1].trim();
                            currentPart.headers.add(new Header(name, value));
                        }
                    }
                    else {
                        currentPart.content.add(line);
                    }
                }
            }
            
            return parts;
        }
        
        private static String findHeader(List<Header> headers, String name) {
            for (Header header : headers) {
                if (header.name.equalsIgnoreCase(name)) {
                    return header.value;
                }
            }
            return '';
        }
        
        private static List<String> extractTextContent(List<String> content) {
            List<String> textContent = new List<String>();
            
            // for (String line : content) {
            //     textContent.add(line.trim());
            // }
            for (String line : content) {
                line = line.trim();
                if (!String.isBlank(line)) {
                    textContent.add(line);
                }
            }
            
            return textContent;
        }
    

    // public class Header {
    //     public String name;
    //     public String value;
        
    //     public Header(String name, String value) {
    //         this.name = name;
    //         this.value = value;
    //     }
    // }
    
    // public class MessagePart {
    //     public List<Header> headers;
    //     public List<String> content;
        
    //     public MessagePart() {
    //         headers = new List<Header>();
    //         content = new List<String>();
    //     }
    // }
    
    // public static List<String> parseText(String message) {
    //     List<String> parsedText = new List<String>();
        
    //     // Split the message into individual lines
    //     List<String> lines = message.split('\n');
        
    //     // Find the boundary string
    //     String boundary = findBoundary(lines);
    //     system.debug('---boundary--'+boundary);
    //     if (String.isBlank(boundary)) {
    //         return parsedText; // No boundary found
    //     }
        
    //     // Parse the message parts
    //     List<MessagePart> parts = splitMessageParts(lines, boundary);
    //     system.debug('---parts--'+json.serialize(parts));
        
    //     // Extract text content from each part
    //     for (MessagePart part : parts) {
    //         system.debug('---part--'+part);
    //         String partContentType = findHeader(part.headers, 'Content-Type');
    //         if (partContentType.toLowerCase() == 'text/plain') {
    //             List<String> textLines = extractTextContent(part.content);
    //             parsedText.addAll(textLines);
    //         }
    //     }
        
    //     return parsedText;
    // }
    
    // private static String findBoundary(List<String> lines) {
    //     //for (String line : lines) {
    //     for(Integer i = 0; i < lines.size(); i++) {
    //         String line = lines[i]; 
    //         system.debug('---line--'+json.serialize(line));
    //         if (line.startsWith('Content-Type: multipart')) {
    //             line = lines[i+1];
    //             // Extract the boundary string
    //             Integer boundaryIndex = line.indexOf('boundary=');
    //             if (boundaryIndex >= 0) {
    //                 String boundary = line.substring(boundaryIndex + 9);
    //                 return boundary.trim();
    //             }
    //             break;
    //         }
    //     }
    //     return '';
    // }
    
    // private static List<MessagePart> splitMessageParts(List<String> lines, String boundary) {
    //     List<MessagePart> parts = new List<MessagePart>();
    //     MessagePart currentPart = null;
        
    //     for (String line : lines) {
    //         system.debug('---split-'+json.serialize(line));
    //         if (line.startsWith('--' + boundary)) {
    //             if (currentPart != null) {
    //                 parts.add(currentPart);
    //             }
    //             currentPart = new MessagePart();
    //         } else if (line.startsWith('Content-Type:')) {
    //             String[] headerParts = line.substring(13).split(':');
    //             if (headerParts.size() == 2) {
    //                 String name = headerParts[0].trim();
    //                 String value = headerParts[1].trim();
    //                 currentPart.headers.add(new Header(name, value));
    //             }
    //         } else if (currentPart != null) {
    //             currentPart.content.add(line);
    //         }
    //     }
        
    //     if (currentPart != null) {
    //         parts.add(currentPart);
    //     }
        
    //     return parts;
    // }
    
    // private static String findHeader(List<Header> headers, String name) {
    //     for (Header header : headers) {
    //         if (header.name.equalsIgnoreCase(name)) {
    //             return header.value;
    //         }
    //     }
    //     return '';
    // }
    
    // private static List<String> extractTextContent(List<String> content) {
    //     List<String> textContent = new List<String>();
        
    //     for (String line : content) {
    //         textContent.add(line.trim());
    //     }
        
    //     return textContent;
    // }

    



    // private String fullHeader;
    // private String html;
    // private List<MIMEImageData> images;
    // private String text;
    // private String mimeData;

    // public class MIMEImageData {
    //     public String ID;
    //     public String Data;
    // }

    // public String getFullHeader() {
    //     return fullHeader;
    // }

    // public String getHTML() {
    //     return html;
    // }

    // public String getText() {
    //     return text;
    // }

    // public String getImageData(String id) {
    //     for (MIMEImageData image : images) {
    //         if (image.ID == id) {
    //             return image.Data;
    //         }
    //     }
    //     // If not found, return empty string
    //     return '';
    // }

    // public EMLParser parse(String value) {
    //     mimeData = value;
    //     text = value;//EncodingUtil.base64Decode(mimeData).toString();
    //     List<String> parts = text.split('\r\n\r\n');
    //     fullHeader = parts[0];
    //     images = new List<MIMEImageData>();

    //     for (Integer partIndex = 0; partIndex < parts.size(); partIndex++) {
    //         if (parts[partIndex].contains('Content-Type: text/html;')) {
    //             html = parts[partIndex + 1];

    //             // Remove incomplete escape code for "=" and line breaks at the end
    //             html = html.replace('=', '').replaceAll('=\r\n', '');
    //         }
    //         if (parts[partIndex].contains('Content-Type: image/')) {
    //             List<String> imgTag = parts[partIndex].split('\r\n');
    //             String imgData = parts[partIndex + 1];
    //             String imgID = '';
    //             for (String tag : imgTag) {
    //                 if (tag.contains('Content-ID: ')) {
    //                     imgID = 'cid:' + tag.split(': ')[1].replace('<', '').replace('>', '');
    //                 }
    //             }
    //             MIMEImageData img = new MIMEImageData();
    //             img.Data = imgData;
    //             img.ID = imgID;
    //             images.add(img);
    //         }
    //     }
    //     return this;
    // }
    
    
    // public EMLParser() {

    // }

    // public class EmlReadResult {
    //     public Date date1;
    //     public String subject;
    //     public String from1;
    //     public String to;
    //     public String cc;
    //     public Map<String, String> headers;
    //     public String html;
    //     public String text;
    //     public List<EmlAttachment> attachments;
    // }

    // public class EmlAttachment {
    //     public String id;
    //     public String name;
    //     public String contentType;
    //     public Boolean inline;
    //     public Blob data;
    // }

    // private static List<String> splitLines(String emlContent) {
    //     List<String> lines = new List<String>();
    //     Integer startIndex = 0;
    //     Integer endIndex = emlContent.indexOf('\r\n', startIndex);
        
    //     while (endIndex != -1) {
    //         lines.add(emlContent.substring(startIndex, endIndex));
    //         startIndex = endIndex + 2;
    //         endIndex = emlContent.indexOf('\r\n', startIndex);
    //     }
        
    //     if (startIndex < emlContent.length()) {
    //         lines.add(emlContent.substring(startIndex));
    //     }
        
    //     return lines;
    // }

    // public static EmlReadResult read(String eml) {
    //     return read(eml, null);
    // }

    // public static EmlReadResult read(String eml, Map<String, Object> options) {
    //     EmlReadResult result = new EmlReadResult();
    //     result.headers = new Map<String, String>();

    //     String[] lines = eml.split('\\r?\\n');//splitLines(eml);//eml.split('\\r?\\n');
    //     Boolean insideBody = false;
    //     Boolean isMultipart = false;
    //     String boundary = null;
    //     String lastHeaderName = '';
    //     String findBoundary = '';
    //     Boolean insideBoundary = false;
    //     Boolean isMultiHeader = false;
    //     List<String> bodyLines = new List<String>();
    //     List<EmlAttachment> attachments = new List<EmlAttachment>();
    //     Map<String, EmlAttachment> cidMap = new Map<String, EmlAttachment>();

    //     for (Integer i = 0; i < lines.size(); i++) {
    //         String line = lines[i];
    //         system.debug('----line--'+json.serialize(line));

    //         if (!insideBody) {
    //             if (line == '') {
    //                 insideBody = true;

    //                 String contentType = result.headers.get('Content-Type');
    //                 if (contentType != null && contentType.startsWith('multipart/')) {
    //                     boundary = getBoundary(contentType);
    //                     if (boundary != null && boundary != '') {
    //                         findBoundary = boundary;
    //                         isMultipart = true;
    //                     }
    //                 }

    //                 continue;
    //             }

    //             Pattern patternLineMatches = Pattern.compile('^\\s+[^\\r\\n]+');
    //             Matcher matcherLines = patternLineMatches.matcher(line);
    //             if(matcherLines.matches()){
    //             //if (line.matches('^\\s+[^\\r\\n]+')) {
    //                 if (isMultiHeader) {
    //                     result.headers.put(lastHeaderName, result.headers.get(lastHeaderName) + '\\r\\n' + line.trim());
    //                 } else {
    //                     result.headers.put(lastHeaderName, line.trim());
    //                 }
    //                 continue;
    //             }

    //             Pattern pattern = Pattern.compile('^([\\w\\d\\-]+):\\s+([^\r\n]+)');
    //             Matcher matcher = pattern.matcher(line);
    //             if (matcher.find()) {
    //                 lastHeaderName = matcher.group(1);
    //                 if (result.headers.containsKey(lastHeaderName)) {
    //                     isMultiHeader = true;
    //                     result.headers.put(lastHeaderName, matcher.group(2));
    //                     // if (result.headers.get(lastHeaderName) instanceof List<String>) {
    //                         // ((List<String>) result.headers.get(lastHeaderName)).add(matcher.group(2));
    //                     // } else {
    //                         // List<String> multiHeader = new List<String>();
    //                         // multiHeader.add((String) result.headers.get(lastHeaderName));
    //                         // multiHeader.add(matcher.group(2));
    //                         // result.headers.put(lastHeaderName, multiHeader);
    //                     //}
    //                 } else {
    //                     result.headers.put(lastHeaderName, matcher.group(2));
    //                 }
    //             }
    //         } else {
    //             if (isMultipart) {
    //                 if (insideBoundary) {
    //                     if (boundary != null && lines[i - 1] == '' && line.startsWith('--' + findBoundary)) {
    //                         insideBoundary = true;
    //                         if (bodyLines.size() > 0) {
    //                             EmlAttachment attachment = parseAttachment(bodyLines, result.headers);
    //                             if (attachment != null) {
    //                                 attachments.add(attachment);
    //                                 if (attachment.id != null && attachment.id != '') {
    //                                     cidMap.put(attachment.id, attachment);
    //                                 }
    //                             }
    //                         }
    //                         bodyLines.clear();
    //                         continue;
    //                     }

    //                     if (boundary != null && lines[i - 1] == '' && line == '--' + findBoundary + '--') {
    //                         insideBoundary = false;
    //                         if (bodyLines.size() > 0) {
    //                             EmlAttachment attachment = parseAttachment(bodyLines, result.headers);
    //                             if (attachment != null) {
    //                                 attachments.add(attachment);
    //                                 if (attachment.id != null && attachment.id != '') {
    //                                     cidMap.put(attachment.id, attachment);
    //                                 }
    //                             }
    //                         }
    //                         break;
    //                     }

    //                     bodyLines.add(line);
    //                 }
    //             } else {
    //                 result.text = String.join(bodyLines, '\\r\\n');
    //                 break;
    //             }
    //         }
    //     }

    //     result.attachments = attachments;
    //     result.html = getHtmlContent(cidMap, result.headers);

    //     return result;
    // }

    // private static EmlAttachment parseAttachment(List<String> lines, Map<String, String> headers) {
    //     EmlAttachment attachment = new EmlAttachment();
    //     attachment.inline = false;

    //     for (String line : lines) {
    //         if (line.startsWith('Content-ID:')) {
    //             attachment.id = line.substring(line.indexOf(':') + 1).trim();
    //         } else if (line.startsWith('Content-Disposition:')) {
    //             String disposition = line.substring(line.indexOf(':') + 1).trim();
    //             attachment.inline = disposition.equalsIgnoreCase('inline');
    //             if (disposition.toLowerCase().contains('name=')) {
    //                 String name = disposition.substring(disposition.toLowerCase().indexOf('name=') + 5).trim();
    //                 if (name.startsWith('\"') && name.endsWith('\"')) {
    //                     name = name.substring(1, name.length() - 1);
    //                 }
    //                 attachment.name = name;
    //             }
    //         } else if (line.startsWith('Content-Type:')) {
    //             attachment.contentType = line.substring(line.indexOf(':') + 1).trim();
    //         } else if (line.startsWith('Content-Transfer-Encoding:')) {
    //             String encoding = line.substring(line.indexOf(':') + 1).trim().toLowerCase();
    //             if (encoding.equals('base64')) {
    //                 attachment.data = EncodingUtil.base64Decode(String.join(lines, ''));
    //             } else {
    //                 attachment.data = Blob.valueOf(String.join(lines, '\\r\\n'));
    //             }
    //         }
    //     }

    //     return attachment;
    // }

    // private static String getBoundary(String contentType) {
    //     Pattern pattern = Pattern.compile('boundary=([^\\s]+)');
    //     Matcher matcher = pattern.matcher(contentType);
    //     if (matcher.find()) {
    //         return matcher.group(1);
    //     }
    //     return null;
    // }

    // private static String getHtmlContent(Map<String, EmlAttachment> cidMap, Map<String, String> headers) {
    //     String contentType = headers.get('Content-Type');
    //     if (contentType != null && contentType.contains('text/html')) {
    //         String content = headers.get('Content-Transfer-Encoding');
    //         if (content != null && content.equalsIgnoreCase('base64')) {
    //             EmlAttachment data = cidMap.get(content);
    //             if (data != null) {
    //                 return data.data.toString();
    //             }
    //         }
    //     }
    //     return null;
    // }
}

// public class EMLParser {
//     // Default character set
//     private static String defaultCharset = 'utf-8'; // to use if charset=... is missing

//     // Gets the character encoding name for iconv, e.g. 'iso-8859-2' -> 'iso88592'
//     private static String getCharsetName(String charset) {
//         return charset.toLowerCase().replaceAll('[^0-9a-z]', '');
//     }

//     // Generates a random id
//     private String generateGUID() {
//         String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
//         String guid = '';
//         while (guid.length() < 32) {
//             Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
//             guid += chars.substring(index, index + 1);
//         }
//         return guid;
//     }

//     // Word-wrap the string 's' to 'i' chars per row
//     private List<String> wrap(String s, Integer i) {
//         List<String> parts = new List<String>();
//         while (s.length() > 0) {
//             parts.add(s.substring(0, Math.min(i, s.length())));
//             s = s.substring(i);
//         }
//         return parts;
//     }

//     // Overridable properties and functions
//     public class EmlFormat {
//         Boolean verbose = false;
//         Map<String, String> fileExtensions = new Map<String, String>{
//             'text/plain' => '.txt',
//             'text/html' => '.html',
//             'image/png' => '.png',
//             'image/jpg' => '.jpg',
//             'image/jpeg' => '.jpg'
//         };

//         // Gets file extension by mime type
//         private String getFileExtension(String mimeType) {
//             return fileExtensions.containsKey(mimeType) ? fileExtensions.get(mimeType) : '';
//         }

//         // Gets the boundary name
//         private String getBoundary(String contentType) {
//             String pattern1 = 'boundary="?(.+?)"?(\\s*;[\\s\\S]*)?$';
//             Pattern regex = Pattern.compile(pattern1);
//             Matcher matcher = regex.matcher(contentType);
//             if (matcher.find()) {
//                 return matcher.group(1);
//             }
//             return null;
//         }

//         // Gets character set name, e.g. contentType='.....charset="iso-8859-2"....'
//         private String getCharset(String contentType) {
//             String pattern1 = 'charset\\s*=\\W*([\\w\\-]+)';
//             Pattern regex = Pattern.compile(pattern1);
//             Matcher matcher = regex.matcher(contentType);
//             if (matcher.find()) {
//                 return matcher.group(1);
//             }
//             return null;
//         }

//         // Gets name and e-mail address from a string, e.g. "PayPal" <noreply@paypal.com> => { name: "PayPal", email: "noreply@paypal.com" }
//         private Object getEmailAddress(String raw) {
//             List<Object> list1 = new List<Object>();
//             List<String> parts = raw.split(',');

//             for (String part : parts) {
//                 Map<String, String> address = new Map<String, String>();

//                 if (part.startsWith('"')) {
//                     Integer endIndex = part.indexOf('"', 1);
//                     if (endIndex > 0) {
//                         address.put('name', unquoteString(part.substring(1, endIndex).replace('"', '').trim()));
//                         part = part.substring(endIndex + 1).trim();
//                     }
//                 }

//                 String pattern1 = '^(.*?)(\\s*\\<(.*?)\\>)$';
//                 Pattern regex = Pattern.compile(pattern1);
//                 Matcher matcher = regex.matcher(part);
//                 if (matcher.find()) {
//                     String name = unquoteString(matcher.group(1).replace('"', '').trim());
//                     if (name != null && name.length() > 0) {
//                         address.put('name', name);
//                     }
//                     address.put('email', matcher.group(3).trim());
//                     list1.add(address);
//                 } else {
//                     address.put('email', part.trim());
//                     list1.add(address);
//                 }
//             }

//             if (list1.size() == 0) {
//                 return null; // No e-mail address
//             } else if (list1.size() == 1) {
//                 return list1.get(0); // Only one record, return as object, required to preserve backward compatibility
//             } else {
//                 return list1; // Multiple e-mail addresses as array
//             }
//         }

//         // Builds e-mail address string, e.g. { name: "PayPal", email: "noreply@paypal.com" } => "PayPal" <noreply@paypal.com>
//         private String toEmailAddress(Object data) {
//             String email = '';
//             if (data == null) {
//                 // No e-mail address
//             } else if (data instanceof String) {
//                 email = (String)data;
//             } else if (data instanceof List<Object>) {
//                 List<Object> dataList = (List<Object>)data;
//                 for (Integer i = 0; i < dataList.size(); i++) {
//                     email += (email.length() > 0 ? ', ' : '');
//                     if (((Map<String, String>)dataList.get(i)).containsKey('name')) {
//                         email += '"' + ((Map<String, String>)dataList.get(i)).get('name') + '"';
//                     }
//                     if (((Map<String, String>)dataList.get(i)).containsKey('email')) {
//                         email += (email.length() > 0 ? ' ' : '') + '<' + ((Map<String, String>)dataList.get(i)).get('email') + '>';
//                     }
//                 }
//             } else if (data instanceof Map<String, String>) {
//                 if (((Map<String, String>)data).containsKey('name')) {
//                     email += '"' + ((Map<String, String>)data).get('name') + '"';
//                 }
//                 if (((Map<String, String>)data).containsKey('email')) {
//                     email += (email.length() > 0 ? ' ' : '') + '<' + ((Map<String, String>)data).get('email') + '>';
//                 }
//             }
//             return email;
//         }

//         // Decodes string by detecting the charset
//         private String unquoteString(String s) {
//             String pattern1 = '=\\?([^?]+)\\?(B|Q)\\?(.+?)(\\?=)';
//             Pattern regex = Pattern.compile(pattern1);
//             Matcher matcher = regex.matcher(s);
//             if (matcher.find()) {
//                 String charset = getCharsetName(matcher.group(1) != null ? matcher.group(1) : defaultCharset);
//                 String type = matcher.group(2) != null ? matcher.group(2).toUpperCase() : null;
//                 String value = matcher.group(3) != null ? matcher.group(3) : null;
//                 if (type == 'B') { // Base64
//                     if (charset == 'utf8') {
//                         return EncodingUtil.base64Decode(value.replace('\n', '')).toString();
//                     } else {
//                         return null;//return EncodingUtil.base64Decode(value.replace('\n', '')).toString(charset);
//                     }
//                 } else if (type == 'Q') { // Quoted-printable
//                     value = value.replaceAll('_', ' '); // Replace underscore with space
//                     return EncodingUtil.urlDecode(value, charset);
//                 }
//             }
//             return s;
//         }
//     }
// }


// public class EMLParser {

    



//     public class EmailContent {
//         public String subject;
//         public String from1;
//         public List<String> to;
//         public String body;
//     }

//     public static void parseEmail(String emlContent) {
//         // Parse MIME attributes
//         List<String> headers = splitLines(emlContent);
//         Map<String, String> mimeAttributes = new Map<String, String>();
//         for (String header : headers) {
//             if (header.contains(':')) {
//                 List<String> headerParts = header.split(':', 2);
//                 String key = headerParts[0].trim();
//                 String value = headerParts[1].trim();
//                 mimeAttributes.put(key, value);
//             }
//         }

//         // Get text content and HTML content
//         String textContent = '';
//         String htmlContent = '';

//         // Check if the email has multipart content
//         if (mimeAttributes.containsKey('Content-Type') && mimeAttributes.get('Content-Type').startsWith('multipart')) {
//             // Find the boundaries of each part
//             String boundary = '--' + mimeAttributes.get('Content-Type').substringAfter('boundary=');
//             List<String> parts = emlContent.split(boundary);

//             // Iterate through each part and find text and HTML content
//             for (String part : parts) {
//                 if (part.contains('Content-Type: text/plain')) {
//                     // Extract text content
//                     textContent = part.substringAfter('\r\n\r\n').trim();
//                 } else if (part.contains('Content-Type: text/html')) {
//                     // Extract HTML content
//                     htmlContent = part.substringAfter('\r\n\r\n').trim();
//                 }
//             }
//         } else {
//             // If the email is not multipart, consider the whole content as text
//             textContent = emlContent;
//         }

//         // Perform further processing with the parsed data as needed
//         System.debug('MIME Attributes: ' + json.serialize(mimeAttributes));
//         System.debug('Text Content: ' + json.serialize(textContent));
//         System.debug('HTML Content: ' + json.serialize(htmlContent));
//     }
    
//     private static List<String> splitLines(String emlContent) {
//         List<String> lines = new List<String>();
//         Integer startIndex = 0;
//         Integer endIndex = emlContent.indexOf('\n', startIndex);
        
//         while (endIndex != -1) {
//             lines.add(emlContent.substring(startIndex, endIndex));
//             startIndex = endIndex + 1;
//             endIndex = emlContent.indexOf('\n', startIndex);
//         }
        
//         if (startIndex < emlContent.length()) {
//             lines.add(emlContent.substring(startIndex));
//         }
        
//         return lines;
//     }
// }
// public class EMLParser {
//     public class EmailContent {
//         public Map<String, String> headers;
//         public String body;
//     }

//     public static EmailContent parseEML(String emlBody) {
//         EmailContent emailContent = new EmailContent();
//         emailContent.headers = new Map<String, String>();

//         Integer bodyIndex = emlBody.toLowerCase().indexOf('\r\n\r\n');
//         if (bodyIndex != -1) {
//             emailContent.body = emlBody.substring(bodyIndex + 4);
//             String headerSection = emlBody.substring(0, bodyIndex);

//             List<String> headerLines = headerSection.split('\r\n');
//             for (String line : headerLines) {
//                 Integer colonIndex = line.indexOf(':');
//                 if (colonIndex != -1) {
//                     String key = line.substring(0, colonIndex).trim();
//                     String value = line.substring(colonIndex + 1).trim();
//                     emailContent.headers.put(key, value);
//                 }
//             }
//         }

//         return emailContent;
//     }
// }
// public class EMLParser {
//     public class EmailContent {
//         public String subject;
//         public String from1;
//         public String to;
//         public String bodyText;
//         public String bodyHtml;
//     }

//     public static EmailContent parseEML(String emlBody) {
//         EmailContent emailContent = new EmailContent();

//         Integer subjectIndex = emlBody.toLowerCase().indexOf('subject:');
//         Integer fromIndex = emlBody.toLowerCase().indexOf('from:');
//         Integer toIndex = emlBody.toLowerCase().indexOf('to:');
//         Integer bodyTextIndex = emlBody.toLowerCase().indexOf('content-type: text/plain;');
//         Integer bodyHtmlIndex = emlBody.toLowerCase().indexOf('content-type: text/html;');

//         if (subjectIndex != -1) {
//             Integer subjectEndIndex = emlBody.indexOf('\n', subjectIndex);
//             emailContent.subject = emlBody.substring(subjectIndex + 8, subjectEndIndex).trim();
//         }

//         if (fromIndex != -1) {
//             Integer fromEndIndex = emlBody.indexOf('\n', fromIndex);
//             emailContent.from1 = emlBody.substring(fromIndex + 5, fromEndIndex).trim();
//         }

//         if (toIndex != -1) {
//             Integer toEndIndex = emlBody.indexOf('\n', toIndex);
//             emailContent.to = emlBody.substring(toIndex + 3, toEndIndex).trim();
//         }

//         if (bodyTextIndex != -1) {
//             Integer bodyTextEndIndex = emlBody.indexOf('\n\n', bodyTextIndex);
//             emailContent.bodyText = emlBody.substring(bodyTextEndIndex + 2).trim();
//         }

//         if (bodyHtmlIndex != -1) {
//             Integer bodyHtmlEndIndex = emlBody.indexOf('\n\n', bodyHtmlIndex);
//             emailContent.bodyHtml = emlBody.substring(bodyHtmlEndIndex + 2).trim();
//         }

//         return emailContent;
//     }
// }
// public class EMLParser {
//     public class EmailContent {
//         public String subject;
//         public String from1;
//         public String to;
//         public String bodyText;
//         public String bodyHtml;
//     }

//     public static EmailContent parseEML(String emlBody) {
//         EmailContent emailContent = new EmailContent();

//         String subjectPattern = '(?i)Subject:\\s*(.+)';
//         String fromPattern = '(?i)From:\\s*(.+)';
//         String toPattern = '(?i)To:\\s*(.+)';
//         String bodyTextPattern = '(?is)(Content-Type:\\s*text/plain;.+?)(\\r?\\n){2}(.+?)(\\r?\\n)--';
//         String bodyHtmlPattern = '(?is)(Content-Type:\\s*text/html;.+?)(\\r?\\n){2}(.+?)(\\r?\\n)--';

//         Pattern subjectRegex = Pattern.compile(subjectPattern);
//         Pattern fromRegex = Pattern.compile(fromPattern);
//         Pattern toRegex = Pattern.compile(toPattern);
//         Pattern bodyTextRegex = Pattern.compile(bodyTextPattern);
//         Pattern bodyHtmlRegex = Pattern.compile(bodyHtmlPattern);

//         Matcher subjectMatcher = subjectRegex.matcher(emlBody);
//         Matcher fromMatcher = fromRegex.matcher(emlBody);
//         Matcher toMatcher = toRegex.matcher(emlBody);
//         Matcher bodyTextMatcher = bodyTextRegex.matcher(emlBody);
//         Matcher bodyHtmlMatcher = bodyHtmlRegex.matcher(emlBody);

//         if (subjectMatcher.find()) {
//             emailContent.subject = subjectMatcher.group(1);
//         }

//         if (fromMatcher.find()) {
//             emailContent.from1 = fromMatcher.group(1);
//         }

//         if (toMatcher.find()) {
//             emailContent.to = toMatcher.group(1);
//         }

//         if (bodyTextMatcher.find()) {
//             emailContent.bodyText = bodyTextMatcher.group(3);
//         }

//         if (bodyHtmlMatcher.find()) {
//             emailContent.bodyHtml = bodyHtmlMatcher.group(3);
//         }

//         return emailContent;
//     }
// }