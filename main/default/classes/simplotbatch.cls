public class simplotbatch implements Database.Batchable<sObject>, Database.Stateful{
    
    //private testpharosx.Logger logger = testpharosx.Logger.getInstance();
    private testpharosx.Log logger = testpharosx.Log.instance;
    
    public simplotbatch() {
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext ctx) {
        Database.QueryLocator queryLocator = Database.getQueryLocator([
            SELECT Id FROM Contact LIMIT 3
        ]);
        return queryLocator; 
    }
    
    public void execute(Database.BatchableContext ctx, List<sObject> objList) {
        List<Contact> cts = (List<Contact>)objList;
        try {
            Database.SaveResult[] sr = Database.update(cts, false);
            this.logger.handleUpdateResults(sr);
            //integer i = 10/0;
        }
        catch(Exception e) {
            this.logger.addError(Log.Area.Accounts, e);
            /*testpharosx.Logger logger = testpharosx.Logger.getInstance();
            String err1 = String.valueOf(e);
            logger?.add(
                Log.newBuilder()
                .category('Error') 
                .type('test32')
                .area('area32')
                .summary('error'+e.getMessage())
                .details(String.valueOf(e))
                .stackTrace(err1)
                //.stackTrace(e.getStackTraceString())
                .build()); 
            logger.flushAsync();*/
            
        }
    }
    
    public void finish(Database.BatchableContext ctx){
        this.logger?.flush();
    }
}