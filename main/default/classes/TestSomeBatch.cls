public class TestSomeBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts,Database.RaisesPlatformEvents{
    private integer counter = 0;
    
    public TestSomeBatch() {
        system.debug('---TestSomeBatch--');
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('---start--');
        Database.QueryLocator queryLocator =  Database.getQueryLocator([
            select id from account limit 1
        ]);
        return queryLocator;
    }

    public void execute(Database.BatchableContext info, List<SObject> scope) {
        system.debug('---execute--');
        List<Log__c> toUpdate = new List<Log__c>();
        toUpdate.add(new Log__c(Id = 'a086g000008SwRU', Resolved_On__c = DateTime.now()));
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
        /*List<testpharosx__TestList1__c> rr = [SELECT id, testpharosx__token__c, testpharosx__refresh__c FROM testpharosx__TestList1__c FOR UPDATE];
        for(testpharosx__TestList1__c r1 : rr) {
            r1.testpharosx__token__c = info.getJobId();
            r1.testpharosx__refresh__c = String.valueOf(counter++);
        }
        update rr;*/
        /*Case [] accts = [SELECT Id, testpharosx__LTA__c FROM Case where id = '5006g00000cq8in' FOR UPDATE];
        for(Case c : accts) {
            c.testpharosx__LTA__c = (c.testpharosx__LTA__c == null) ? '' : c.testpharosx__LTA__c;
            c.testpharosx__LTA__c += 'j=' + info.getJobId() + ',c=' + counter++ +'\r\n';
        }
        update accts;*/
    }
    
    public void finish(Database.BatchableContext info) {
        system.debug('---finish0--');
    }

}