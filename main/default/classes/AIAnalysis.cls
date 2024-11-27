public with sharing class AIAnalysis {

	public List<AI_Event__e> events = new List<AI_Event__e>();
	public Map<String, Issue__c> issues = new Map<String, Issue__c>();
	public Map<String, AIAnalysisService> analysisServiceByIssueId = new Map<String, AIAnalysisService>();

	public static AIAnalysis getInstance() {
		if (instance == null) {
			instance = new AIAnalysis();
		}
		return instance;
	}

	private static AIAnalysis instance = null;

	private AIAnalysis() {
	}

	public void init(List<AI_Event__e> events) {
		this.events = events;
		Set<String> issueIds = new Set<String>();
		for (AI_Event__e event : events) {
			issueIds.add(event.Record_Id__c);
		}
		init(issueIds);
		setResult();
	}

	public void init(Set<String> issueIds) {
		this.issues = getIssues(issueIds);
		for (Issue__c issue : this.issues.values()) {
			this.analysisServiceByIssueId.put(issue.Id, new AIAnalysisService(issue));
		}
		setContentDocumentId();
	}

	public void analysis() {
		for (AIAnalysisService analysisService : analysisServiceByIssueId.values()) {
			analysisService.analysis();
		}
	}

	public void createContentVersions() {
		List<ContentVersion> contentVersions = new List<ContentVersion>();
		for (Issue__c issue : issues.values()) {
			for (String analysis : AIAnalysisService.ANALYSIS_MAP.keySet()) {
				ContentVersion contentVersion = analysisServiceByIssueId.get(issue.Id).createContentVersion(analysis);
				if (contentVersion != null) contentVersions.add(contentVersion);
			}
		}
		DatabaseUtils.getInstance().performUpsertDML(contentVersions, Schema.SObjectType.ContentVersion)
				.handleError(AIAnalysis.class.getName(), '.createContentVersions', Logger.getInstance());
		contentVersions = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions AND IsLatest = TRUE];
		List<ContentDocumentLink> existContentDocumentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :issues.keySet()];
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (Issue__c issue : issues.values()) {
			for (String analysis : AIAnalysisService.ANALYSIS_MAP.keySet()) {
				String title = getTitleString(issue.Name, analysis);
				for (ContentVersion contentVersion : contentVersions) {
					if (title == contentVersion.Title) {
						Boolean isExist = false;
						for (ContentDocumentLink contentDocumentLink : existContentDocumentLinks) {
							if (contentDocumentLink.ContentDocumentId == contentVersion.ContentDocumentId) {
								isExist = true;
								break;
							}
						}
						if (!isExist) {
							ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
							contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
							contentDocumentLink.LinkedEntityId = issue.Id;
							contentDocumentLink.ShareType = 'I';
							contentDocumentLinks.add(contentDocumentLink);
						}
					}
				}
			}
		}
		DatabaseUtils.getInstance().performInsertDML(contentDocumentLinks, Schema.SObjectType.ContentDocumentLink)
				.handleError(AIAnalysis.class.getName(), '.createContentVersions', Logger.getInstance());
	}

	public void flush() {
		for (AIAnalysisService analysisService : analysisServiceByIssueId.values()) {
			analysisService.issueStatus();
		}
		setIssueAnalysisRT();
		DatabaseUtils.getInstance().performUpdateDML(issues.values(), Schema.SObjectType.Issue__c)
				.handleError(AIAnalysis.class.getName(), '.flush', Logger.getInstance());
	}

	private void setContentDocumentId() {
		Map<String, String> contentDocumentIdsByTitle = getContentDocumentIdsByTitle();
		for (Issue__c issue : this.issues.values()) {
			for (String analysis : AIAnalysisService.ANALYSIS_MAP.keySet()) {
				String title = getTitleString(issue.Name, analysis);
				if (contentDocumentIdsByTitle.containsKey(title)) {
					analysisServiceByIssueId.get(issue.Id).setContentDocumentId(analysis, contentDocumentIdsByTitle.get(title));
				}
			}
		}
	}

	private void setResult() {
		for (AI_Event__e event : events) {
			analysisServiceByIssueId.get(event.Record_Id__c).setResult(event.Analysis__c, event.Status__c, event.Result__c);
		}
	}

	private static Map<String, Issue__c> getIssues(Set<String> issueIds) {
		return new Map<String, Issue__c>([
				SELECT
						Id,
						Name,
						Category__c,
						Functional_Area__c,
						First_Occurred_On__c,
						Last_Occurred_On__c,
						Impacted_Objects_Count__c,
						Impacted_Users_Count__c,
						Average_Frequency__c,
						Issue_Analysis__c,
						Analysis_Statuses_Details__c,
						Log__c,
						Log__r.Type__c,
						Log__r.Category__c,
						Log__r.Details__c,
						Log__r.Organization_Id__c,
						Log__r.Related_Objects__c,
						Log__r.Flow_API_Name__c,
						Log__r.Flow_Version__c,
						Log__r.Stacktrace_Parse_Result__c,
						Log__r.Stacktrace__c,
						Log__r.Setup_Audit_Trail__c
				FROM Issue__c
				WHERE Id IN :issueIds]);
	}

	private Map<String, String> getContentDocumentIdsByTitle() {
		Map<String, String> contentDocumentIdsByTitle = new Map<String, String>();
		List<ContentDocumentLink> contentDocumentLinks = [
				SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title
				FROM ContentDocumentLink
				WHERE LinkedEntityId IN :issues.keySet()
		];
		for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
			contentDocumentIdsByTitle.put(contentDocumentLink.ContentDocument.Title, contentDocumentLink.ContentDocumentId);
		}
		return contentDocumentIdsByTitle;
	}

	public void setVersionData() {
		Set<String> titles = new Set<String>();
		for (Issue__c issue : issues.values()) {
			for (String analysis : AIAnalysisService.ANALYSIS_MAP.keySet()) {
				titles.add(getTitleString(issue.Name, analysis));
			}
		}
		List<ContentDocumentLink> contentDocumentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :issues.keySet()];
		Set<String> contentDocumentIds = new Set<String>();
		for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
			contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
		}
		List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND Title IN :titles AND IsLatest = TRUE];
		for (Issue__c issue : issues.values()) {
			for (ContentVersion contentVersion : contentVersions) {
				if (contentVersion.Title.contains(issue.Name)) {
					analysisServiceByIssueId.get(issue.Id).setVersionData(contentVersion.Title.removeStart(issue.Name + '_'), contentVersion.VersionData.toString());
				}
			}
		}
	}

	public String getConvertedData(String issueId, String context) {
		String convertedData = '';
		for (String analysis : AIAnalysisService.ANALYSIS_MAP.keySet()) {
			convertedData += getConvertedData(issueId, analysis, context);
		}
		return convertedData;
	}

	public String getConvertedData(String issueId, String analysis, String context) {
		return analysisServiceByIssueId.get(issueId).getConvertedData(analysis, context);
	}

	public String getHtmlRT(String issueId, String analysis) {
		return analysisServiceByIssueId.get(issueId).getHtmlRT(analysis);
	}

	private void setIssueAnalysisRT() {
		setVersionData();
		for (AIAnalysisService analysisService : analysisServiceByIssueId.values()) {
			analysisService.issueAnalysisRT();
		}
	}

	public static final String AI_ANALYSIS_ENDPOINT = 'https://ai.pharos.ai/ai_pharos_ai';

	public static final String OPEN_AI_MODEL = 'gpt-4o';

	public static String startBasicAnalysis(Issue__c issue) {
		return OpenAI.doChat(issue);
	}

	public static String startCodeExplainAnalysis(Issue__c issue) {
		CodeExplainRequest request = new CodeExplainRequest(issue);
		return startAnalysis(request);
	}

	public static String startFlowAnalysis(Issue__c issue) {
		FlowAnalysisRequest request = new FlowAnalysisRequest(issue);
		return startAnalysis(request);
	}

	public static String startFlowExplainAnalysis(Issue__c issue) {
		FlowExplainAnalysisRequest request = new FlowExplainAnalysisRequest(issue);
		return startAnalysis(request);
	}

	public static String startAuditTrailAnalysis(Issue__c issue) {
		AuditTrailAnalysisRequest request = new AuditTrailAnalysisRequest(issue);
		return startAnalysis(request);
	}

	private static String startAnalysis(BaseRequest request) {
		String result;
		try {
			if (PermissionsUtil.IssueAnalysisEnabled) {
				result = HttpUtils.post(
					AI_ANALYSIS_ENDPOINT,
					JSON.serialize(request),
					HttpUtils.getHeadersContentTypeJSON(),
					200
				);
			}
		}
		catch(Exception e) {
			Logger.getInstance().internalError(e, AIAnalysis.class.getName(), 'startAnalysis');
		}
		return result;
	}

	public static String getTitleString(String issueName, String analysis) {
		return issueName + '_' + analysis;
	}

	public abstract class BaseRequest {
		public String method;
		public String recordId;
		public String logOrgId;
		public String logDetails;
		public String openAiApiKey;
		public String openAiModel;
		public String ns;
		public String instance;
		public String session;
		public Datetime logDate;

		public BaseRequest(Issue__c issue) {
			this.recordId = issue.Id;
			this.logOrgId = issue.Log__r.Organization_Id__c;
			this.logDetails = issue.Log__r.Details__c;
			this.openAiApiKey = ConfigUtil.OPEN_AI_SETTINGS.Token__c;
			this.openAiModel = OPEN_AI_MODEL;
			this.ns = ConfigUtil.nameSpacePrefix; // 'pharos__';
			this.instance = System.Url.getOrgDomainUrl().toExternalForm();
			this.session = EncodingUtil.base64Encode(Blob.valueOf(ConnectedOrgService.getSelfConnectedOrgAccessToken()));
			this.logDate = issue.First_Occurred_On__c;
		}
	}

	public class CodeExplainRequest extends BaseRequest {
		public String logRelatedObjects;
		public String gitApiKey;
		public String gitRepo;
		public String gitOwner;
		public String gitBranch;
		public CodeExplainRequest(Issue__c issue) {
			super(issue);
			this.method = AIAnalysisService.CODE_EXPLAIN_ANALYSIS;
			this.logRelatedObjects = issue.Log__r.Related_Objects__c;
			this.gitApiKey = (String.isBlank(ConfigUtil.GIT_API_SETTINGS.Token__c))
					? ConfigUtil.GIT_API_SETTINGS.oAuth_Token__c
					: ConfigUtil.GIT_API_SETTINGS.Token__c;
			this.gitRepo = GitHubUtils.GIT_REPONAME;
			this.gitOwner = GitHubUtils.GIT_USERNAME;
			this.gitBranch = GitHubUtils.GIT_API_DEFAULT_BASE_BRANCH_REF;
		}
	}

	public class FlowAnalysisRequest extends BaseRequest {
		public String flowApiName;
		public String flowVersion;
		public String flowErrorNode;
		public String flowNodesAfterError;
		public FlowAnalysisRequest(Issue__c issue) {
			super(issue);
			this.method = AIAnalysisService.FLOW_ANALYSIS;
			this.flowApiName = issue.Log__r.Flow_API_Name__c;
			this.flowVersion = issue.Log__r.Flow_Version__c;
			if (String.isNotBlank(issue.Log__r.Stacktrace_Parse_Result__c)) {
				FlowService.FlowAiMeta flowAiMeta = FlowService.getFlowAiMeta(issue.Log__r.Stacktrace_Parse_Result__c);
				this.flowErrorNode = flowAiMeta.errorNode;
				this.flowNodesAfterError = JSON.serialize(flowAiMeta.nodesAfterError);
			}
		}
	}

	public class FlowExplainAnalysisRequest extends BaseRequest {
		public String flowApiName;
		public String flowVersion;
		public FlowExplainAnalysisRequest(Issue__c issue) {
			super(issue);
			this.method = AIAnalysisService.FLOW_EXPLAIN_ANALYSIS;
			this.flowApiName = issue.Log__r.Flow_API_Name__c;
			this.flowVersion = issue.Log__r.Flow_Version__c;
		}
	}

	public class AuditTrailAnalysisRequest extends BaseRequest {
		public String auditTrail;
		public String logCategory;
		public String flowApiName;
		public String flowVersion;
		public String logRelatedObjects;
		public String gitApiKey;
		public String gitRepo;
		public String gitOwner;
		public String gitBranch;
		public AuditTrailAnalysisRequest(Issue__c issue) {
			super(issue);
			this.method = AIAnalysisService.AUDIT_TRAIL_ANALYSIS;
			this.auditTrail = issue.Log__r.Setup_Audit_Trail__c;
			this.logCategory = issue.Log__r.Category__c;
			if (this.logCategory == 'Flow') {
				this.flowApiName = issue.Log__r.Flow_API_Name__c;
				this.flowVersion = issue.Log__r.Flow_Version__c;
			} else {
				this.logRelatedObjects = issue.Log__r.Related_Objects__c;
				this.gitApiKey = (String.isBlank(ConfigUtil.GIT_API_SETTINGS.Token__c))
						? ConfigUtil.GIT_API_SETTINGS.oAuth_Token__c
						: ConfigUtil.GIT_API_SETTINGS.Token__c;
				this.gitRepo = GitHubUtils.GIT_REPONAME;
				this.gitOwner = GitHubUtils.GIT_USERNAME;
				this.gitBranch = GitHubUtils.GIT_API_DEFAULT_BASE_BRANCH_REF;
			}
		}
	}

	public static String getBasicConvertedData(String jsonData, String context) {
		if (String.isNotBlank(jsonData)) {
			try {
				BasicAnalysisResponse basicAnalysisResponse = (BasicAnalysisResponse)JSON.deserialize(jsonData, BasicAnalysisResponse.class);
				return basicAnalysisResponse.getConvertedData(context);
			} catch (JSONException e) {
			}
		}
		return null;
	}

	public static String getExplainConvertedData(String jsonData, String context) {
		if (String.isNotBlank(jsonData)) {
			try {
				ExplainAnalysisResponse explainAnalysisResponse = (ExplainAnalysisResponse)JSON.deserialize(jsonData, ExplainAnalysisResponse.class);
				return explainAnalysisResponse.getConvertedData(context);
			} catch (JSONException e) {
			}
		}
		return null;
	}

	public static String getAuditTrailConvertedData(String jsonData, String context) {
		if (String.isNotBlank(jsonData)) {
			try {
				AuditTrailAnalysisResponse auditTrailAnalysisResponse = (AuditTrailAnalysisResponse)JSON.deserialize(jsonData, AuditTrailAnalysisResponse.class);
				return auditTrailAnalysisResponse.getConvertedData(context);
			} catch (JSONException e) {
			}
		}
		return null;
	}

	public abstract class AnalysisResponse {
		public String context;

		public String convertTitle(String title) {
			if (String.isBlank(title)) return '';
			switch on context {
				when 'LWC', 'AZURE_DEV_OPS', 'TEAMS' {
					return '<br><h3>' + title + '</h3>';
				}
				when 'JIRA' {
					return 'h3. ' + title + '\n';
				}
				when 'SLACK' {
					return '\n*' + title + '*\n';
				}
				when else {
					return '';
				}
			}
		}
		public String convertText(String text) {
			if (String.isBlank(text)) return '';
			switch on context {
				when 'LWC', 'AZURE_DEV_OPS', 'TEAMS' {
					return '<p>' + replaceParagraphTag(text) + '</p>\n';
				}
				when 'JIRA' {
					return replaceHTMLTags(replaceParagraphTag(text))
							.replaceAll('<code>', '{{').replaceAll('</code>', '}}')
							.replaceAll('<li>', '\n * ').replaceAll('</li>', '') + '\n';
				}
				when 'SLACK' {
					return replaceHTMLTags(replaceParagraphTag(text))
							.replaceAll('<code>', '`').replaceAll('</code>', '`')
							.replaceAll('<li>', '\n - ').replaceAll('</li>', '') + '\n';
				}
				when else {
					return '';
				}
			}
		}
		public String replaceParagraphTag(String text) {
			return text.replaceAll('<p>', '').replaceAll('</p>', '');
		}
		public String replaceHTMLTags(String text) {
			return text.replaceAll('<br>', '')
					.replaceAll('<strong>', '*').replaceAll('</strong>', '*')
					.replaceAll('<b>', '*').replaceAll('</b>', '*')
					.replaceAll('<em>', '_').replaceAll('</em>', '_')
					.replaceAll('<ul>', '').replaceAll('</ul>', '')
					.replaceAll('<ol>', '').replaceAll('</ol>', '')
					.replaceAll('&nbsp;', ' ').replaceAll('&quot;', '"')
					.replaceAll('&laquo;', '"').replaceAll('&raquo;', '"');
		}
		public String convertCode(String code) {
			if (String.isBlank(code)) return '';
			switch on context {
				when 'LWC', 'AZURE_DEV_OPS', 'TEAMS' {
					return '<code><pre>' + replaceBackticks(code) + '</pre></code>\n';
				}
				when 'JIRA' {
					return '{code:borderStyle=solid}\n' +
							replaceBackticks(code) +
							'{code}\n';
				}
				when 'SLACK' {
					return '```\n' +
							replaceBackticks(code) +
							'```\n';
				}
				when else {
					return '';
				}
			}
		}
		public String replaceBackticks(String code) {
			return code.replaceAll('```apex', '').replaceAll('```', '').trim() + '\n';
		}
		public String convertOptions(List<String> options) {
			if (options.isEmpty()) return '';
			switch on context {
				when 'LWC', 'AZURE_DEV_OPS', 'TEAMS' {
					String result = '<ul>';
					for (String option : options) {
						result += '<li><p>' + option + '</p></li>';
					}
					result += '</ul>';
					return result;
				}
				when 'JIRA' {
					String result = '';
					for (String option : options) {
						result += '* ' + convertText(option) + '\n';
					}
					return result + '\n';
				}
				when 'SLACK' {
					String result = '';
					for (String option : options) {
						result += '- ' + convertText(option);
					}
					return result + '\n';
				}
				when else {
					return '';
				}
			}
		}
		public String convertTable(List<AuditTrailAnalysisResult> rows) {
			if (rows.isEmpty()) return '';
			switch on context {
				when 'LWC', 'AZURE_DEV_OPS', 'TEAMS' {
					String table = '<br><table style="width: 100%">';
					table += '<thead>' +
							'<tr>' +
							'<th scope="col">ACTION</th>' +
							'<th scope="col">SECTION</th>' +
							'<th scope="col">CREATED&nbsp;BY</th>' +
							'<th scope="col">CREATED&nbsp;DATE</th>' +
							'</tr>' +
							'</thead>';
					table += '<tbody>';
					for (AuditTrailAnalysisResult auditTrailAnalysisResult : rows) {
						table += '<tr style="border-top: 1px solid #e5e5e5; border-bottom: 1px solid #e5e5e5;">' +
								'<td style="white-space: normal">' + auditTrailAnalysisResult.display?.trim() + '</td>' +
								'<td>' + auditTrailAnalysisResult.section?.trim().replaceAll(' ', '&nbsp;') + '</td>' +
								'<td>' + auditTrailAnalysisResult.userName?.trim().replaceAll(' ', '&nbsp;') + '</td>' +
								'<td>' + auditTrailAnalysisResult.createdDate?.trim() + '</td>' +
								'</tr>';
					}
					table += '</tbody>';
					table += '</table>';
					return table;
				}
				when 'JIRA' {
					String table = '\n||ACTION||SECTION||CREATED BY||CREATED DATE||';
					for (AuditTrailAnalysisResult auditTrailAnalysisResult : rows) {
						table += tableRowMarkdown(auditTrailAnalysisResult);
					}
					return table + '\n';
				}
				when 'SLACK' {
					String table = '```\n| ACTION | SECTION | CREATED BY | CREATED DATE |';
					for (AuditTrailAnalysisResult auditTrailAnalysisResult : rows) {
						table += tableRowMarkdown(auditTrailAnalysisResult);
					}
					return table + '```\n';
				}
				when else {
					return '';
				}
			}
		}
		public String tableRowMarkdown(AuditTrailAnalysisResult auditTrailAnalysisResult) {
			return '\n| ' + auditTrailAnalysisResult.display + ' | ' + auditTrailAnalysisResult.section + ' | ' + auditTrailAnalysisResult.userName + ' | ' + auditTrailAnalysisResult.createdDate + ' |';
		}
	}

	public class BasicAnalysisResponse extends AnalysisResponse {
		public String rootCauseAnalysis;
		public List<String> resolutionOptions;
		public String severityEstimate;
		public String justification;

		public String getConvertedData(String context) {
			this.context = context;
			String convertedData = '';
			convertedData += convertTitle('Root Cause Analysis');
			convertedData += convertText(rootCauseAnalysis);
			convertedData += convertTitle('Resolution Options');
			convertedData += convertOptions(resolutionOptions);
			convertedData += convertTitle('Severity Estimate');
			convertedData += convertText(severityEstimate);
			convertedData += convertTitle('Justification');
			convertedData += convertText(justification);
			return convertedData;
		}
	}

	public class ExplainAnalysisResponse extends AnalysisResponse {
		public String title;
		public String summary;
		public String fixed_code;
		public String solution_description;
		public List<ExplainAnalysisSection> sections;

		public String getConvertedData(String context) {
			this.context = context;
			String convertedData = '';
			convertedData += convertTitle(title);
			if (String.isNotBlank(summary)) convertedData += convertText(summary);
			if (String.isNotBlank(fixed_code)) {
				convertedData += convertTitle('Fixed Code');
				convertedData += convertCode(fixed_code);
			}
			if (String.isNotBlank(solution_description)) {
				convertedData += convertTitle('Solution Description');
				convertedData += convertText(solution_description);
			}
			for (ExplainAnalysisSection section : sections) {
				convertedData += convertTitle(section.subtitle);
				convertedData += convertText(section.description);
			}
			return convertedData;
		}
	}

	public class ExplainAnalysisSection {
		public String subtitle;
		public String description;
	}

	public class AuditTrailAnalysisResponse extends AnalysisResponse {
		public String summary;
		public String relevance;
		public List<AuditTrailAnalysisResult> result;
		public String getConvertedData(String context) {
			this.context = context;
			String convertedData = '';
			convertedData += convertTitle('Summary');
			convertedData += convertText(summary);
			convertedData += convertTitle('Relevance');
			convertedData += convertText(relevance);
			convertedData += convertTable(result);
			return convertedData;
		}
	}

	public class AuditTrailAnalysisResult {
		public String id;
		public String action;
		public String createdDate;
		public String display;
		public String section;
		public String userName;
	}

}