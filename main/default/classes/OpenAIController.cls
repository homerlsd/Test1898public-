public with sharing class OpenAIController {

	@AuraEnabled
	public static String checkAnalysisPermission() {
		String result;
		if (!PermissionsUtil.IssueAnalysisEnabled) {
			result = AIAnalysisService.ISSUE_ANALYSIS_DISABLED_MESSAGE;
		} else if (!ConfigUtil.OPEN_AI_SETTINGS.OpenAI_Enabled__c || String.isBlank(ConfigUtil.OPEN_AI_SETTINGS.Token__c)) {
			result = AIAnalysisService.CONFIGURE_OPEN_AI_SETTINGS_MESSAGE;
		}
		return result;
	}

	@AuraEnabled
	public static List<AnalysisStatusDetails> startAnalysis(String recordId) {
		AIAnalysis analysis = AIAnalysis.getInstance();
		analysis.init(new Set<String>{recordId});
		analysis.analysis();
		analysis.createContentVersions();
		analysis.flush();
		return getAnalysis(recordId);
	}

	@AuraEnabled
	public static List<AnalysisStatusDetails> getAnalysis(String recordId) {
		List<AnalysisStatusDetails> result;
		List<AIAnalysisService.AnalysisStatusDetails> analysisStatusesDetails;
		List<Issue__c> issues = [SELECT Id, Name, Analysis_Statuses_Details__c FROM Issue__c WHERE Id = :recordId];
		if (!issues.isEmpty()) {
			if (String.isNotBlank(issues[0].Analysis_Statuses_Details__c)) {
				try {
					analysisStatusesDetails = (List<AIAnalysisService.AnalysisStatusDetails>)JSON.deserialize(issues[0].Analysis_Statuses_Details__c, List<AIAnalysisService.AnalysisStatusDetails>.class);
				} catch (JSONException e) {
					// catch JSON deserialize issue
				}
			}
			if (analysisStatusesDetails != null) {
				AIAnalysis analysis = AIAnalysis.getInstance();
				analysis.init(new Set<String>{recordId});
				analysis.setVersionData();
				result = new List<AnalysisStatusDetails>();
				for (String analysisKey : AIAnalysisService.ANALYSIS_MAP.keySet()) {
					for (AIAnalysisService.AnalysisStatusDetails analysisStatusDetails : analysisStatusesDetails) {
						if (analysisKey == analysisStatusDetails.analysis) {
							AnalysisStatusDetails asd = new AnalysisStatusDetails();
							asd.analysis = analysisStatusDetails.analysis;
							asd.status = analysisStatusDetails.status;
							asd.message = analysisStatusDetails.message;
							asd.result = analysis.getConvertedData(recordId, analysisStatusDetails.analysis, 'LWC');
							result.add(asd);
						}
					}
				}
			}
		}
		return result;
	}

	public class AnalysisStatusDetails {
		@AuraEnabled
		public String analysis;
		@AuraEnabled
		public String status;
		@AuraEnabled
		public String message;
		@AuraEnabled
		public Long lastAnalysisTimestamp;
		@AuraEnabled
		public String result;
	}

}