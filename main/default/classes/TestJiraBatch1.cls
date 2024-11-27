public class TestJiraBatch1 implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts,Database.RaisesPlatformEvents {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Contact
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        for(Integer i = 1; i<100; i++) {
            JiraService.JiraIssue issue = JiraService.getJiraIssueByKey('TES-1', null);
            system.debug(issue);
        }
    }
    
    public void finish(Database.BatchableContext BC){}
}