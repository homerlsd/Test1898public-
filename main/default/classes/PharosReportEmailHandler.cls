global with sharing class PharosReportEmailHandler implements Messaging.InboundEmailHandler {

    private static final String PHAROS_ERROR_REPORT_EMAIL_SUBJECT = 'Pharos Error Email Report:';
    
    global PharosReportEmailHandler() {

    }

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,
    Messaging.InboundEnvelope env) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            String emailText = email.plainTextBody;
            String emailSubject = email.subject;

            if(!email?.binaryAttachments.isEmpty()
                && String.isNotBlank(emailText)
                && String.isNotBlank(emailSubject)
                && emailText.startsWithIgnoreCase(PHAROS_ERROR_REPORT_EMAIL_SUBJECT)) {
                
                createInternalLogs(emailText, email.binaryAttachments);
            }
        }
        catch(Exception e){
            // create logs?
        }
        finally {
            result.success = true;
        }
        
        return result;
    }

    private static void createInternalLogs(String emailText, List<Messaging.Inboundemail.BinaryAttachment> attachments) {
        List<Log__c> toInsert = new List<Log__c>();
        EmailTextWrapper report = (EmailTextWrapper)JSON.deserialize(emailText, EmailTextWrapper.class);

        for(Messaging.Inboundemail.BinaryAttachment file : attachments) {
            Log__c log = (Log__c)JSON.deserialize(file.body.toString(), Log__c.class);
            if(report.comments.containsKey(log.Id)) {
                //log.Comments__c = report.comments.get(log.Id);
            }
            log.Id = null;
            toInsert.add(log);
        }

        insert toInsert;
    }

    public class EmailTextWrapper {
        public String organizationId;
        public String reportedBy;
        public Map<String, String> comments;
    }
}