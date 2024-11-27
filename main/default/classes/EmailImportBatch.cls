public with sharing class EmailImportBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts,Database.RaisesPlatformEvents {

    public String parentId;
    
    public EmailImportBatch(String parentId) {
        this.parentId = parentId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator([
            SELECT 
                Id, BodyLength
            FROM Attachment
            WHERE ParentId = :this.parentId
		]);
	}

    public void execute(Database.BatchableContext BC, List<Attachment> scope) {
		try {
            List<Attachment> attachments = (List<Attachment>)scope;
            Attachment attachment = attachments.get(0);
            
            if(attachment.BodyLength < 6000000) {
                Attachment cv = [SELECT Body FROM Attachment WHERE Id = :attachment.Id LIMIT 1];
                MIMEMessageService service = new MIMEMessageService(cv.Body.toString());
                if(String.isNotBlank(service.subject)) {
                    Messaging.inboundEmail im = new Messaging.inboundEmail();
                    im.subject = service.subject;
                    if(String.isNotBlank(service.html)) {
                        im.htmlBody = service.html;
                    }
                    else {
                        im.plainTextBody = service.text;
                    }

                    im.headers = new List<Messaging.InboundEmail.Header>();
                    Messaging.InboundEmail.Header dateHeader = new Messaging.InboundEmail.Header();
                    dateHeader.value = service.dateHeader;
                    dateHeader.name = 'Date';
                    Messaging.InboundEmail.Header fromHeader = new Messaging.InboundEmail.Header();
                    fromHeader.value = service.fromHeader;
                    fromHeader.name = 'From';
                    im.headers.add(dateHeader);
                    im.headers.add(fromHeader);

                    im.fromAddress = service.fromAddress;
                    im.fromName = service.fromName;

                    System.enqueueJob(new AsyncEmailProcess(im));
                }
            }
            
        }
        catch(Exception e) {
            // log error
        }
    }

    public class AsyncEmailProcess implements Queueable, Database.AllowsCallouts {
        public Messaging.inboundEmail im;
        
        public AsyncEmailProcess(Messaging.inboundEmail im) {
            this.im = im;
        }
        
        public void execute(QueueableContext context) {
            ErrorEmailHandler eh = new ErrorEmailHandler();
            eh.handleInboundEmail(this.im, null);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {}
}