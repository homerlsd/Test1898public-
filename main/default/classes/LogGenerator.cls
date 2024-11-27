public class LogGenerator implements Database.Batchable<Integer>{
    
   private Integer total;
    
   public LogGenerator(Integer total) {
       this.total = total;
   }
   public Iterable<Integer> start(Database.BatchableContext info){
       return new CustomIterable(this.total);
   }
   
   public void execute(Database.BatchableContext info, List<Integer> scope){
       /* suda vstavit code po clone */    
   }
   
   public void finish(Database.BatchableContext info){
   }
   
   public class CustomIterator implements Iterator<Integer>{ 
     
       private Integer total;
       private Integer currentIndex;
     
       public CustomIterator(Integer total){
           this.total = total;
           this.currentIndex = 0;
       }
     
       public Boolean hasNext(){ 
           return currentIndex < total;
       }    
     
       public Integer next(){
           if(hasNext()) {
               return currentIndex++;
           }
           else {
               throw new NoSuchElementException('Iterator has no more elements.');
           }
       } 
    }
   
   public class CustomIterable implements Iterable<Integer> {
       private Integer total;
       public CustomIterable(Integer total) {
           this.total = total;
       }
       public Iterator<Integer> iterator(){
          return new CustomIterator(this.total);
       }
    }
}