public with sharing class AiEventTriggerHandler {

	public static void aiEventHandler(List<AI_Event__e> events) {
		AIAnalysis analysis = AIAnalysis.getInstance();
		analysis.init(events);
		analysis.createContentVersions();
		analysis.flush();
	}

}