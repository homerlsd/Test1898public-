public with sharing class AIAnalysisService {

	public enum Analysis {
		BASIC,
		CODE_EXPLAIN,
		FLOW,
		FLOW_EXPLAIN,
		AUDIT_TRAIL
	}

	private enum Category {
		APEX,
		ERROR,
		INTEGRATION,
		FLOW,
		PROCESS_BUILDER
	}

	private enum Status {
		NOT_STARTED,
		IN_PROGRESS,
		NOT_APPLICABLE,
		CONFIGURATION_REQUIRED,
		COMPLETED,
		FAILED
	}

	public static final String BASIC_ANALYSIS = 'basic';
	public static final String CODE_EXPLAIN_ANALYSIS = 'code_explain';
	public static final String FLOW_ANALYSIS = 'flow';
	public static final String FLOW_EXPLAIN_ANALYSIS = 'flow_explain';
	public static final String AUDIT_TRAIL_ANALYSIS = 'audit_trail';

	public static final Map<String, Analysis> ANALYSIS_MAP = new Map<String, Analysis>{
			BASIC_ANALYSIS => Analysis.BASIC,
			CODE_EXPLAIN_ANALYSIS => Analysis.CODE_EXPLAIN,
			FLOW_ANALYSIS => Analysis.FLOW,
			FLOW_EXPLAIN_ANALYSIS => Analysis.FLOW_EXPLAIN,
			AUDIT_TRAIL_ANALYSIS => Analysis.AUDIT_TRAIL
	};

	public static final Map<String, String> ANALYSIS_TITLE_MAP = new Map<String, String>{
			BASIC_ANALYSIS => 'Basic Analysis',
			CODE_EXPLAIN_ANALYSIS => 'Code Explanation',
			FLOW_ANALYSIS => 'Flow Analysis',
			FLOW_EXPLAIN_ANALYSIS => 'Flow Explanation',
			AUDIT_TRAIL_ANALYSIS => 'Audit Trail Analysis'
	};

	private static final String APEX_CATEGORY = 'Apex';
	private static final String ERROR_CATEGORY = 'Error';
	private static final String INTEGRATION_CATEGORY = 'Integration';
	private static final String FLOW_CATEGORY = 'Flow';
	private static final String PROCESS_BUILDER_CATEGORY = 'Process Builder';

	private static final Map<String, Category> CATEGORY_MAP = new Map<String, Category>{
			APEX_CATEGORY => Category.APEX,
			ERROR_CATEGORY => Category.ERROR,
			INTEGRATION_CATEGORY => Category.INTEGRATION,
			FLOW_CATEGORY => Category.FLOW,
			PROCESS_BUILDER_CATEGORY => Category.PROCESS_BUILDER
	};

	public static final String NOT_STARTED_STATUS = 'Not Started';
	public static final String IN_PROGRESS_STATUS = 'In Progress';
	public static final String NOT_APPLICABLE_STATUS = 'Not Applicable';
	public static final String CONFIGURATION_REQUIRED_STATUS = 'Configuration Required';
	public static final String COMPLETED_STATUS = 'Completed';
	public static final String FAILED_STATUS = 'Failed';

	public static final String AWS_ERROR_STATUS = 'error';
	public static final Integer ANALYSIS_TIMEOUT_MIN = 30;

	private static final Set<String>  CODE_ANALYSIS_CATEGORIES = new Set<String> {APEX_CATEGORY, ERROR_CATEGORY, INTEGRATION_CATEGORY};
	private static final Set<String>  FLOW_ANALYSIS_CATEGORIES = new Set<String> {FLOW_CATEGORY, PROCESS_BUILDER_CATEGORY};

	// CONFIGURE NEEDED
	public static final String ISSUE_ANALYSIS_DISABLED_MESSAGE = 'Issue Analysis is not available for your org. For pricing and enablement please contact sales@pharos.ai.';
	public static final String CONFIGURE_OPEN_AI_SETTINGS_MESSAGE = 'To utilize Issue Analysis first configure the OpenAI settings under Pharos Admin -> Integrations -> OpenAI. To request an OpenAI token please reach out to success@pharos.ai';
	private static final String CONFIGURE_CHANGE_TRACKING_MESSAGE = 'Code and flow analysis requires Change Tracking feature to be enabled in Pharos Admin -> Change Tracking.  If that menu option is not available please contact success@pharos.ai for enablement.';

	private static final Map<String, Status> STATUS_MAP = new Map<String, Status>{
			NOT_STARTED_STATUS => Status.NOT_STARTED,
			IN_PROGRESS_STATUS => Status.IN_PROGRESS,
			NOT_APPLICABLE_STATUS => Status.NOT_APPLICABLE,
			CONFIGURATION_REQUIRED_STATUS => Status.CONFIGURATION_REQUIRED,
			COMPLETED_STATUS => Status.COMPLETED,
			FAILED_STATUS => Status.FAILED
	};

	private final Issue__c issue;
	private final Map<Analysis, AIAnalysisServiceInterface> strategies;

	public AIAnalysisService(Issue__c issue) {
		this.issue = issue;
		this.strategies = new Map<Analysis, AIAnalysisServiceInterface>();
		for (Analysis analysis : Analysis.values()) {
			this.strategies.put(analysis, getAIAnalysisServiceInterface(analysis, this.issue));
		}
	}

	public void analysis() {
		for (AIAnalysisServiceInterface strategy : this.strategies.values()) {
			strategy.analysis();
		}
	}

	public void issueStatus() {
		List<AnalysisStatusDetails> analysisStatusesDetails = new List<AnalysisStatusDetails>();
		issue.Analysis_Status__c = NOT_STARTED_STATUS;
		for (AIAnalysisServiceInterface strategy : this.strategies.values()) {
			AnalysisStatusDetails analysisStatusDetails = strategy.getAnalysisStatusDetails();
			if (analysisStatusDetails.status == IN_PROGRESS_STATUS) issue.Analysis_Status__c = IN_PROGRESS_STATUS;
			if (issue.Analysis_Status__c != IN_PROGRESS_STATUS
					&& analysisStatusDetails.status == COMPLETED_STATUS) issue.Analysis_Status__c = COMPLETED_STATUS;
			if (issue.Analysis_Status__c != IN_PROGRESS_STATUS
					&& issue.Analysis_Status__c != COMPLETED_STATUS
					&& analysisStatusDetails.status == FAILED_STATUS) issue.Analysis_Status__c = FAILED_STATUS;
			analysisStatusesDetails.add(analysisStatusDetails);
		}
		issue.Analysis_Statuses_Details__c = JSON.serialize(analysisStatusesDetails);
	}

	public void setContentDocumentId(String analysis, String contentDocumentId) {
		this.strategies.get(ANALYSIS_MAP.get(analysis)).setContentDocumentId(contentDocumentId);
	}

	public void setResult(String analysis, String status, String result) {
		this.strategies.get(ANALYSIS_MAP.get(analysis)).setResult(status, result);
	}

	public ContentVersion createContentVersion(String analysis) {
		return this.strategies.get(ANALYSIS_MAP.get(analysis)).createContentVersion();
	}

	public void setVersionData(String analysis, String versionData) {
		this.strategies.get(ANALYSIS_MAP.get(analysis)).setVersionData(versionData);
	}

	public void issueAnalysisRT() {
		issue.Issue_Analysis__c = '';
		for (String analysis : ANALYSIS_MAP.keySet()) {
			String htmlRT = getHtmlRT(analysis);
			if (String.isNotBlank(htmlRT)) {
				issue.Issue_Analysis__c += '<h2>' + ANALYSIS_TITLE_MAP.get(analysis) + '</h2>';
				issue.Issue_Analysis__c += htmlRT;
			}
		}
	}

	public String getConvertedData(String analysis, String context) {
		return this.strategies.get(ANALYSIS_MAP.get(analysis)).getConvertedData(context);
	}

	public String getHtmlRT(String analysis) {
		return this.strategies.get(ANALYSIS_MAP.get(analysis)).getHtmlRT();
	}

	public interface AIAnalysisServiceInterface {
		void analysis();
		void changeStatus(String status, String message);
		void setContentDocumentId(String contentDocumentId);
		void setResult(String status, String result);
		void setVersionData(String versionData);
		ContentVersion createContentVersion();
		AnalysisStatusDetails getAnalysisStatusDetails();
		String getConvertedData(String context);
		String getHtmlRT();
	}

	public abstract class AIAnalysisServiceAbstract implements AIAnalysisServiceInterface {
		private final Issue__c issue;
		private AnalysisStatusDetails analysisStatusDetails;
		private String result;
		private String contentDocumentId;
		private String versionData;
		public AIAnalysisServiceAbstract(String analysis, Issue__c issue) {
			this.issue = issue;
			if (String.isNotBlank(this.issue.Analysis_Statuses_Details__c)) {
				List<AnalysisStatusDetails> analysisStatusesDetails = new List<AnalysisStatusDetails>();
				try {
					analysisStatusesDetails = (List<AnalysisStatusDetails>)JSON.deserialize(this.issue.Analysis_Statuses_Details__c, List<AnalysisStatusDetails>.class);
				} catch (JSONException e) {
					// catch JSON deserialize issue
				}
				AnalysisStatusDetails analysisStatusDetails;
				for (AnalysisStatusDetails asd : analysisStatusesDetails) {
					if (asd.analysis == String.valueOf(analysis)) {
						analysisStatusDetails = asd;
						break;
					}
				}
				this.analysisStatusDetails = analysisStatusDetails;
			}
			if (this.analysisStatusDetails == null) {
				this.analysisStatusDetails = new AnalysisStatusDetails();
				this.analysisStatusDetails.analysis = analysis;
				changeStatus(NOT_STARTED_STATUS);
			}
			if (this.analysisStatusDetails.status == CONFIGURATION_REQUIRED_STATUS || this.analysisStatusDetails.status == NOT_APPLICABLE_STATUS) {
				changeStatus(NOT_STARTED_STATUS);
			}
			// CONFIGURATION_REQUIRED
			if (!PermissionsUtil.IssueAnalysisEnabled) {
				changeStatus(CONFIGURATION_REQUIRED_STATUS, ISSUE_ANALYSIS_DISABLED_MESSAGE);
			}
			if (!ConfigUtil.OPEN_AI_SETTINGS.OpenAI_Enabled__c || String.isBlank(ConfigUtil.OPEN_AI_SETTINGS.Token__c)) {
				changeStatus(CONFIGURATION_REQUIRED_STATUS, CONFIGURE_OPEN_AI_SETTINGS_MESSAGE);
			}
		}
		public virtual void changeStatus(String status) {
			analysisStatusDetails.status = status;
		}
		public virtual void changeStatus(String status, String message) {
			analysisStatusDetails.status = status;
			analysisStatusDetails.message = message;
		}
		public virtual void setLastAnalysisTimestamp() {
			analysisStatusDetails.lastAnalysisTimestamp = System.now().getTime();
		}
		public virtual void analysis() {
			if (analysisStatusDetails.status == NOT_STARTED_STATUS
					|| analysisStatusDetails.status == COMPLETED_STATUS
					|| analysisStatusDetails.status == FAILED_STATUS
					|| (analysisStatusDetails.status == IN_PROGRESS_STATUS && isTimeoutOver())) {
				changeStatus(IN_PROGRESS_STATUS);
				setLastAnalysisTimestamp();
				doAnalysis();
			}
		}
		public virtual void doAnalysis() {}
		public virtual Boolean isTimeoutOver() {
			return analysisStatusDetails.lastAnalysisTimestamp == null || ((System.now().getTime() - analysisStatusDetails.lastAnalysisTimestamp) / 1000 / 60 >= ANALYSIS_TIMEOUT_MIN);
		}
		public virtual AnalysisStatusDetails getAnalysisStatusDetails() {
			return analysisStatusDetails;
		}
		public virtual void setContentDocumentId(String contentDocumentId) {
			this.contentDocumentId = contentDocumentId;
		}
		public virtual void setResult(String status, String result) {
			if (status == AWS_ERROR_STATUS) {
				changeStatus(FAILED_STATUS, result);
			} else {
				this.result = result;
			}
		}
		public virtual void setVersionData(String versionData) {
			this.versionData = versionData;
		}
		public virtual String getConvertedData(String context) {
			return '';
		}
		public virtual String getHtmlRT() {
			return '';
		}
		public virtual ContentVersion createContentVersion() {
			ContentVersion contentVersion;
			if (String.isNotBlank(result)) {
				changeStatus(COMPLETED_STATUS, null);
				String title = AIAnalysis.getTitleString(issue.Name, analysisStatusDetails.analysis);
				contentVersion = new ContentVersion();
				if (String.isNotBlank(contentDocumentId)) contentVersion.ContentDocumentId = contentDocumentId;
				contentVersion.PathOnClient = title + '.json';
				contentVersion.VersionData = Blob.valueOf(result);
				contentVersion.Description = title;
				contentVersion.ContentLocation = 'S';
				contentVersion.IsMajorVersion = true;
			}
			return contentVersion;
		}
	}

	// APEX ABSTRACT
	public abstract class ApexAIAnalysisServiceAbstract extends AIAnalysisServiceAbstract {
		public ApexAIAnalysisServiceAbstract(String analysis, Issue__c issue) {
			super(analysis, issue);
			// APPLICABLE
			if (CODE_ANALYSIS_CATEGORIES.contains(issue.Category__c)) {
				// CONFIGURATION_REQUIRED
				if (!ConfigUtil.CHANGE_TRACKING_SETTINGS.Git_Change_Tracking__c) {
					changeStatus(CONFIGURATION_REQUIRED_STATUS, CONFIGURE_CHANGE_TRACKING_MESSAGE);
				}
			} else {
				changeStatus(NOT_APPLICABLE_STATUS, null);
			}
		}
	}

	// FLOW ABSTRACT
	public abstract class FlowAIAnalysisServiceAbstract extends AIAnalysisServiceAbstract {
		public FlowAIAnalysisServiceAbstract(String analysis, Issue__c issue) {
			super(analysis, issue);
			// APPLICABLE
			if (!FLOW_ANALYSIS_CATEGORIES.contains(issue.Category__c)) {
				changeStatus(NOT_APPLICABLE_STATUS, null);
			}
		}
	}

	// BASIC
	public class BasicAIAnalysisService extends AIAnalysisServiceAbstract {
		public BasicAIAnalysisService(String analysis, Issue__c issue) {
			super(analysis, issue);
		}
		public override void doAnalysis() {
			result = AIAnalysis.startBasicAnalysis(issue);
		}
		public override String getConvertedData(String context) {
			return versionData != null && analysisStatusDetails.status == COMPLETED_STATUS ? AIAnalysis.getBasicConvertedData(versionData, context) : '';
		}
	}

	// CODE_EXPLAIN
	public class CodeExplainAIAnalysisService extends ApexAIAnalysisServiceAbstract {
		public CodeExplainAIAnalysisService(String analysis, Issue__c issue) {
			super(analysis, issue);
		}
		public override void doAnalysis() {
			AIAnalysis.startCodeExplainAnalysis(issue);
		}
		public override String getConvertedData(String context) {
			return versionData != null && analysisStatusDetails.status == COMPLETED_STATUS ? AIAnalysis.getExplainConvertedData(versionData, context) : '';
		}
	}

	// FLOW
	public class FlowAIAnalysisService extends FlowAIAnalysisServiceAbstract {
		public FlowAIAnalysisService(String analysis, Issue__c issue) {
			super(analysis, issue);
		}
		public override void doAnalysis() {
			AIAnalysis.startFlowAnalysis(issue);
		}
		public override String getConvertedData(String context) {
			return versionData != null && analysisStatusDetails.status == COMPLETED_STATUS ? AIAnalysis.getExplainConvertedData(versionData, context) : '';
		}
	}

	// FLOW_EXPLAIN
	public class FlowExplainAIAnalysisService extends FlowAIAnalysisServiceAbstract {
		public FlowExplainAIAnalysisService(String analysis, Issue__c issue) {
			super(analysis, issue);
		}
		public override void doAnalysis() {
			AIAnalysis.startFlowExplainAnalysis(issue);
		}
		public override String getConvertedData(String context) {
			return versionData != null && analysisStatusDetails.status == COMPLETED_STATUS ? AIAnalysis.getExplainConvertedData(versionData, context) : '';
		}
	}

	// AUDIT_TRAIL
	public class AuditTrailAIAnalysisService extends AIAnalysisServiceAbstract {
		public AuditTrailAIAnalysisService(String analysis, Issue__c issue) {
			super(analysis, issue);
			if (String.isBlank(issue.Log__r.Setup_Audit_Trail__c)) {
				changeStatus(NOT_APPLICABLE_STATUS, null);
			}
			if (CODE_ANALYSIS_CATEGORIES.contains(issue.Category__c)) {
				// CONFIGURATION_REQUIRED
				if (!ConfigUtil.CHANGE_TRACKING_SETTINGS.Git_Change_Tracking__c) {
					changeStatus(CONFIGURATION_REQUIRED_STATUS, CONFIGURE_CHANGE_TRACKING_MESSAGE);
				}
			}
		}
		public override void doAnalysis() {
			AIAnalysis.startAuditTrailAnalysis(issue);
		}
		public override String getConvertedData(String context) {
			return versionData != null && analysisStatusDetails.status == COMPLETED_STATUS ? AIAnalysis.getAuditTrailConvertedData(versionData, context) : '';
		}
	}

	private static AIAnalysisServiceInterface getAIAnalysisServiceInterface(Analysis analysis, Issue__c issue) {
		switch on analysis {
			when BASIC {
				return new BasicAIAnalysisService(BASIC_ANALYSIS, issue);
			}
			when CODE_EXPLAIN {
				return new CodeExplainAIAnalysisService(CODE_EXPLAIN_ANALYSIS, issue);
			}
			when FLOW {
				return new FlowAIAnalysisService(FLOW_ANALYSIS, issue);
			}
			when FLOW_EXPLAIN {
				return new FlowExplainAIAnalysisService(FLOW_EXPLAIN_ANALYSIS, issue);
			}
			when AUDIT_TRAIL {
				return new AuditTrailAIAnalysisService(AUDIT_TRAIL_ANALYSIS, issue);
			}
			when else {
				return null;
			}
		}
	}

	public class AnalysisStatusDetails {
		public String analysis;
		public String status;
		public String message;
		public Long lastAnalysisTimestamp;
	}

}