public with sharing class SystemOverviewController {

	@TestVisible
	private static final Map<String, String> CODE_INFO_OBJECTS_MAP = new Map<String, String>{
			'ApexClass' => 'Apex Class',
			'ApexTrigger' => 'Apex Trigger',
			'ApexPage' => 'Apex Page',
			'ApexComponent' => 'Apex Component',
			'LightningComponentBundle' => 'LWC',
			'AuraDefinitionBundle' => 'Aura',
			'FlowDefinition' => 'Flow'
	};
	private static final Set<String> CODE_INFO_OBJECTS_TOOLING = new Set<String>{'LightningComponentBundle', 'FlowDefinition'};
	private static final Set<String> CODE_INFO_OBJECTS_MASTER_LABEL = new Set<String>{'LightningComponentBundle', 'AuraDefinitionBundle', 'FlowDefinition'};
	private static final Set<String> CODE_INFO_OBJECTS_NAME = new Set<String>{'ApexClass', 'ApexTrigger', 'ApexPage', 'ApexComponent'};

	@TestVisible
	private static final String CODE_INFO_QUERY = 'SELECT COUNT(Id) count_id, NamespacePrefix namespacePrefix FROM {0} GROUP BY NamespacePrefix';

	private static final String CODE_INFO_DETAILS_QUERY = 'SELECT Name, ApiVersion, NamespacePrefix FROM {0}';
	@TestVisible
	private static final String CODE_INFO_DETAILS_LIGHTNING_QUERY = 'SELECT MasterLabel, ApiVersion, NamespacePrefix FROM {0}';
	@TestVisible
	private static final String CODE_INFO_DETAILS_FLOW_QUERY = 'SELECT MasterLabel, MAX(ApiVersion) ApiVersion, Definition.Id, Definition.NamespacePrefix FROM Flow GROUP BY MasterLabel, Definition.Id, Definition.NamespacePrefix';
	private static final String PROGRESS_COLOR_SUCCESS = '#2e844a';
	private static final String PROGRESS_COLOR_WARNING = '#fe9339';
	private static final String PROGRESS_COLOR_ERROR = '#ea001e';

	@AuraEnabled
	public static Organization getOrgInfo() {
		return [SELECT Id, Name, OrganizationType, CreatedDate, IsSandbox, LanguageLocaleKey, TimeZoneSidKey FROM Organization];
	}

	@AuraEnabled
	public static UsersInfo getUsersInfo() {
		UsersInfo usersInfo = new UsersInfo();
		usersInfo.numberOfActiveUsers = [SELECT COUNT() FROM User WHERE IsActive = TRUE];
		usersInfo.numberOfActiveUsersForLast30Days = [SELECT COUNT() FROM User WHERE IsActive = TRUE AND CreatedDate >= LAST_N_DAYS:30];
		usersInfo.numberOfUsers = [SELECT COUNT() FROM User];
		usersInfo.numberOfInactiveUsers = [SELECT COUNT() FROM User WHERE IsActive = FALSE];
		return usersInfo;
	}

	@AuraEnabled
	public static List<CodeInfo> getCodeInfo() {
		List<CodeInfo> lstCodeInfo = new List<CodeInfo>();
		for (String objectName : CODE_INFO_OBJECTS_MAP.keySet()) {
			CodeInfo codeInfo = new CodeInfo();
			codeInfo.name = objectName;
			codeInfo.label = CODE_INFO_OBJECTS_MAP.get(objectName);
			String query = String.format(CODE_INFO_QUERY, new List<String>{objectName});
			if (CODE_INFO_OBJECTS_TOOLING.contains(objectName)) {
				List<Object> objects = getToolingAPIObjects(query);
				for (Object obj : objects) {
					Map<String, Object> objectMap = (Map<String, Object>)obj;
					codeInfo.namespacePrefix = (String)objectMap.get('namespacePrefix');
					codeInfo.count = (Integer)objectMap.get('count_id');
				}
			} else {
				List<AggregateResult> aggregateResults = Database.query(query);
				for (AggregateResult aggregateResult : aggregateResults) {
					codeInfo.namespacePrefix = (String)aggregateResult.get('namespacePrefix');
					codeInfo.count = (Integer)aggregateResult.get('count_id');
				}
			}
			lstCodeInfo.add(codeInfo);
		}
		return lstCodeInfo;
	}

	@AuraEnabled
	public static List<CodeInfoDetail> getCodeInfoDetails(String objectName) {
		List<CodeInfoDetail> codeInfoDetails = new List<CodeInfoDetail>();
		String query;
		if (objectName == 'FlowDefinition') {
			query = CODE_INFO_DETAILS_FLOW_QUERY;
		} else if (objectName == 'LightningComponentBundle' || objectName == 'AuraDefinitionBundle') {
			query = String.format(CODE_INFO_DETAILS_LIGHTNING_QUERY, new List<String>{objectName});
		} else {
			query = String.format(CODE_INFO_DETAILS_QUERY, new List<String>{objectName});
		}
		if (CODE_INFO_OBJECTS_TOOLING.contains(objectName)) {
			List<Object> objects = getToolingAPIObjects(query);
			for (Object obj : objects) {
				Map<String, Object> objectMap = (Map<String, Object>)obj;
				CodeInfoDetail codeInfoDetail = new CodeInfoDetail();
				codeInfoDetail.name = objectName;
				codeInfoDetail.label = CODE_INFO_OBJECTS_MAP.get(objectName);
				codeInfoDetail.fullName = (String)objectMap.get('MasterLabel');
				codeInfoDetail.namespacePrefix = (String)objectMap.get('NamespacePrefix');
				codeInfoDetail.apiVersion = String.valueOf(objectMap.get('ApiVersion'));
				codeInfoDetails.add(codeInfoDetail);
			}
		} else {
			List<SObject> sObjects = Database.query(query);
			for (SObject sObj : sObjects) {
				CodeInfoDetail codeInfoDetail = new CodeInfoDetail();
				codeInfoDetail.name = objectName;
				codeInfoDetail.label = CODE_INFO_OBJECTS_MAP.get(objectName);
				codeInfoDetail.fullName = objectName == 'AuraDefinitionBundle' ? (String)sObj.get('MasterLabel') : (String)sObj.get('Name');
				codeInfoDetail.namespacePrefix = (String)sObj.get('NamespacePrefix');
				codeInfoDetail.apiVersion = String.valueOf(sObj.get('ApiVersion'));
				codeInfoDetails.add(codeInfoDetail);
			}
		}
		return codeInfoDetails;
	}

	public static List<Object> getToolingAPIObjects(String query) {
		Connected_Org__c corg = ConnectedOrgService.getConnectedOrgById(UserInfo.getOrganizationId());
		return HttpUtils.runToolingQuery(
				corg == null ? System.Url.getOrgDomainUrl().toExternalForm() : corg.Instance_Url__c,
				corg == null ? ConfigUtil.USER_SESSION_ID : ConnectedOrgService.getConnectedOrgAccessToken(corg),
				query,
				ConfigUtil.TOOLING_QUERY_API_ENDPOINT);
	}

	@AuraEnabled
	public static List<SystemOrgLimit> getSystemOrgLimits() {
		Map<String,System.OrgLimit> mapOrgLimits = OrgLimits.getMap();
		List<SystemOrgLimit> systemOrgLimits = new List<SystemOrgLimit>();
		for (String key : mapOrgLimits.keySet()) {
			OrgLimit orgLimit = mapOrgLimits.get(key);
			SystemOrgLimit systemOrgLimit = new SystemOrgLimit();
			systemOrgLimit.name = orgLimit.getName();
			systemOrgLimit.orgLimit = orgLimit.getLimit();
			systemOrgLimit.orgValue = orgLimit.getValue();
			if (systemOrgLimit.orgLimit == 0) {
				systemOrgLimit.progressPercentage = 0;
			} else if (systemOrgLimit.orgValue >= systemOrgLimit.orgLimit) {
				systemOrgLimit.progressPercentage = 100;
			} else {
				systemOrgLimit.progressPercentage = Decimal.valueOf(systemOrgLimit.orgValue) * 100 / systemOrgLimit.orgLimit;
			}
			if (systemOrgLimit.progressPercentage <= 50) {
				systemOrgLimit.progressColor = PROGRESS_COLOR_SUCCESS;
			} else if (systemOrgLimit.progressPercentage <= 80) {
				systemOrgLimit.progressColor = PROGRESS_COLOR_WARNING;
			} else {
				systemOrgLimit.progressColor = PROGRESS_COLOR_ERROR;
			}
			systemOrgLimits.add(systemOrgLimit);
		}
		return systemOrgLimits;
	}

	public class UsersInfo {
		@AuraEnabled
		public Integer numberOfActiveUsers;
		@AuraEnabled
		public Integer numberOfActiveUsersForLast30Days;
		@AuraEnabled
		public Integer numberOfUsers;
		@AuraEnabled
		public Integer numberOfInactiveUsers;
	}

	public class CodeInfo {
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String namespacePrefix;
		@AuraEnabled
		public Integer count;
	}

	public class CodeInfoDetail {
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String fullName;
		@AuraEnabled
		public String apiVersion;
		@AuraEnabled
		public String namespacePrefix;
	}

	public class SystemOrgLimit {
		@AuraEnabled
		public String name;
		@AuraEnabled
		public Integer orgLimit;
		@AuraEnabled
		public Integer orgValue;
		@AuraEnabled
		public Decimal progressPercentage;
		@AuraEnabled
		public String progressColor;
	}

}