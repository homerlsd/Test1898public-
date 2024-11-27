public class testapexlog {

    public Integer getCount() {
        List<AggregateResult> t1 = [SELECT SUM(LogLength) totalSumm, COUNT(Id) totalCount, AVG(LogLength) avgSize FROM ApexLog];
    
        Integer count = [SELECT COUNT() FROM ApexLog];
        return count;
    }
}