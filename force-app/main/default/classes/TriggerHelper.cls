public class TriggerHelper {
	
    public static Map<String, Set<String>> triggerHandlersMap;
    
    static{
        triggerHandlersMap = new Map<String, Set<String>>();
    }
    
  	public static void add(String triggerName){
        if(triggerHandlersMap.containsKey(triggerName)){
            triggerHandlersMap.get(triggerName).add(Trigger.operationType.name());
        }else{
            triggerHandlersMap.put(triggerName,new Set<String>{Trigger.operationType.name()});
        }
  	}

    public static Boolean runOnce(String triggerName) {
        return triggerHandlersMap.containsKey(triggerName) && triggerHandlersMap.get(triggerName).contains(Trigger.operationType.name());
  	}
}