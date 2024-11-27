public class CustomContactTriggerHanlder {
    
    public class Helper {
        private List<testpharosx__CustomContact__c> contacts;
        public Helper(List<testpharosx__CustomContact__c> contacts) {
            this.contacts = contacts;
        }
        public void handle() {
            for(testpharosx__CustomContact__c c : this.contacts) {
                c.put('CreatedDate', DateTime.now());
            }
            update this.contacts;
        }
    }

}