public  class TestFailBatch implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator queryLocator = Database.getQueryLocator([
            SELECT Id, CreatedDate FROM Contact limit 5
            //SELECT Id, CreatedDate FROM Account where id = '0016g00000xruOcAAI' limit 1
        ]);
        return queryLocator;
    }

    public void execute(Database.batchableContext info, List<SObject> scope) {
        List<Contact> contacts = (List<Contact>)scope;
        //for(Contact c : contacts) {
        //    c.put('Department', 'Departments22');
        //}
        update contacts;
    }

    public void finish(Database.batchableContext inf) {
        //System.setPassword('1231231231','13212312');
    }
    
    @Future
    public static void test111() {
        insert new Case(Status = 'New', Origin = 'Email');
    }
}