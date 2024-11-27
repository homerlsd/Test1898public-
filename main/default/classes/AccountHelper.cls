public class AccountHelper {

    public static void updateAccountFields(Account a, Account oldA) {
        Map<Id,Id> map1;
        if(a.Site == oldA.Site) {
                map1.get(a.Id);
            }
    }
    
    @future
    public static void futurecall(Id accountid){
        Account a = new Account(Id = accountid);
        a.OwnerId = '123123123';
        update a;
    }
}