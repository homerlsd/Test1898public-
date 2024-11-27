public with sharing class CacheUtils {

	public static final Integer DEFAULT_TTL = 0;
	public static final Integer KEY_CACHE_LIMIT = 50;

	public static final String KEY_REQUEST_AUDIT_TRAIL = 'RAT';
	public static final String KEY_REQUEST_AUDIT_TRAIL_TTL = 'RequestAuditTrailTTL';

	public static final String KEY_REQUEST_AUTH_SESSIONS = 'RAS';
	public static final String KEY_REQUEST_AUTH_SESSIONS_TTL = 'RequestAuthSessionsTTL';

	public static final String KEY_REQUEST_PACKAGES_INFO = 'RPI';
	public static final String KEY_REQUEST_PACKAGES_INFO_TTL = 'RequestPackagesInfoTTL';

	public static final String KEY_REQUEST_DEPLOYMENT_JOBS = 'RDJ';
	public static final String KEY_REQUEST_DEPLOYMENT_JOBS_TTL = 'RequestDeploymentJobsTTL';

	public static final String KEY_REQUEST_ASYNC_JOBS = 'RAJ';
	public static final String KEY_REQUEST_ASYNC_JOBS_TTL = 'RequestAsyncJobsTTL';

	public static final String KEY_REQUEST_USER_INFO = 'RUI';
	public static final String KEY_REQUEST_USER_INFO_TTL = 'RequestUserInfoTTL';

	public static final String KEY_REQUEST_SOBJECT_DESCRIBE = 'RSD';
	public static final String KEY_REQUEST_SOBJECT_DESCRIBE_TTL = 'RequestSobjectDescribeTTL';

	public static final String KEY_REQUEST_FLOW_DESCRIBE = 'RFD';
	public static final String KEY_REQUEST_FLOW_DESCRIBE_TTL = 'RequestFlowDescribeTTL';

	public static final String KEY_REQUEST_STACK_TRACE = 'RST';
	public static final String KEY_REQUEST_STACK_TRACE_TTL = 'RequestStackTraceTTL';

	public static final String KEY_REQUEST_ENCRYPTED_TOKEN = 'RET';
	public static final String KEY_REQUEST_ENCRYPTED_TOKEN_TTL = 'RequestEncryptedTokenTTL';

	public static final String KEY_REQUEST_ENCRYPTED_JIRA_TOKEN = 'REJT';
	public static final Integer REQUEST_ENCRYPTED_JIRA_TOKEN_TTL = 60*60; // 60 min
	public static final String KEY_REQUEST_ENCRYPTED_JIRA_REFRESH_TOKEN = 'REJRT';
	public static final Integer REQUEST_ENCRYPTED_JIRA_REFRESH_TOKEN_TTL = 24*60*60; // 24 hours

	public static final String KEY_REQUEST_ENCRYPTED_GRAPH_TOKEN = 'REGT';
	public static final Integer REQUEST_ENCRYPTED_GRAPH_TOKEN_TTL = 60*60; // 60 min

	public static final String KEY_REQUEST_ENCRYPTED_AZURE_DEV_OPS_TOKEN = 'READOT';
	public static final Integer REQUEST_ENCRYPTED_AZURE_DEV_OPS_TOKEN_TTL = 60*60; // 60 min

	public static final String KEY_REQUEST_METADATA_RETRIEVE_REQUEST = 'MRR';
	public static final Integer REQUEST_METADATA_RETRIEVE_REQUEST_TTL = 20*60; // 20 min

	public static final String KEY_JIRA_ROTATION_TOKENS_LOCKED_BY_JOB_ID = 'JRTLB';
	public static final Integer JIRA_ROTATION_TOKENS_LOCKED_BY_JOB_ID_TTL = 5*60; // 5 min

	public static final String KEY_GRAPH_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID = 'GALB';
	public static final Integer KEY_GRAPH_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID_TTL = 5*60; // 5 min

	public static final String KEY_AZURE_DEV_OPS_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID = 'AALB';
	public static final Integer KEY_AZURE_DEV_OPS_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID_TTL = 5*60; // 5 min

	public static final String KEY_POST_PROCESSING_LOG_TRACKING = 'PPLT';
	public static final Integer KEY_POST_PROCESSING_LOG_TRACKING_TTL = 20*60; // 20 min

	public static final String KEY_NOTIFICATION_OBJECT_TRACKING = 'NOT';
	public static final Integer KEY_NOTIFICATION_OBJECT_TRACKING_TTL = 24*60*60; // 24 hours

	public static final String KEY_POST_PROCESSING_ORCHESTRATOR_LOG_TRACKING = 'OPPLT';
	public static final Integer KEY_POST_PROCESSING_ORCHESTRATOR_LOG_TRACKING_TTL = 20*60; // 20 min

	public static final String KEY_REQUEST_RELATED_SOBJECT = 'RRS';
	public static final Integer KEY_REQUEST_RELATED_SOBJECT_TTL = 5*60; // 5 min

	public static final String KEY_REQUEST_FAILED_JOB_IDS = 'RFJI';
	public static final Integer KEY_REQUEST_FAILED_JOB_IDS_TTL = 24*60*60; // 24 hours

	public static final String KEY_REQUEST_NOTIFICATION_TIMESTAMP = 'NDTS';
	public static final Integer KEY_REQUEST_NOTIFICATION_TIMESTAMP_TTL = 5*60; // 5 min

	public static final String PARTITION_NAME = 'PharosPartition';
	public static final String FULL_PARTITION_NAME = Cache.OrgPartition.createFullyQualifiedPartition(ConfigUtil.getNameSpace(), PARTITION_NAME);


	public static final Map<String, Integer> MapRequests {
		get {
			if(MapRequests == null) {
				MapRequests = new Map<String, Integer>();
				MapRequests.put(KEY_REQUEST_AUDIT_TRAIL, PermissionsUtil.RequestAuditTrailTTL);
				MapRequests.put(KEY_REQUEST_AUTH_SESSIONS, PermissionsUtil.RequestAuthSessionsTTL);
				MapRequests.put(KEY_REQUEST_PACKAGES_INFO, PermissionsUtil.RequestPackagesInfoTTL);
				MapRequests.put(KEY_REQUEST_DEPLOYMENT_JOBS, PermissionsUtil.RequestDeploymentJobsTTL);
				MapRequests.put(KEY_REQUEST_ASYNC_JOBS, PermissionsUtil.RequestAsyncJobsTTL);
				MapRequests.put(KEY_REQUEST_USER_INFO, PermissionsUtil.RequestUserInfoTTL);
				MapRequests.put(KEY_REQUEST_SOBJECT_DESCRIBE, PermissionsUtil.RequestSobjectDescribeTTL);
				MapRequests.put(KEY_REQUEST_FLOW_DESCRIBE, PermissionsUtil.RequestSobjectDescribeTTL);
				MapRequests.put(KEY_REQUEST_STACK_TRACE, PermissionsUtil.RequestStackTraceTTL);
				MapRequests.put(KEY_REQUEST_ENCRYPTED_TOKEN, PermissionsUtil.RequestEncryptedTokenTTL);
				MapRequests.put(KEY_REQUEST_ENCRYPTED_JIRA_TOKEN, REQUEST_ENCRYPTED_JIRA_TOKEN_TTL);
				MapRequests.put(KEY_REQUEST_ENCRYPTED_JIRA_REFRESH_TOKEN, REQUEST_ENCRYPTED_JIRA_REFRESH_TOKEN_TTL);
				MapRequests.put(KEY_REQUEST_ENCRYPTED_GRAPH_TOKEN, REQUEST_ENCRYPTED_GRAPH_TOKEN_TTL);
				MapRequests.put(KEY_REQUEST_METADATA_RETRIEVE_REQUEST, REQUEST_METADATA_RETRIEVE_REQUEST_TTL);
				MapRequests.put(KEY_JIRA_ROTATION_TOKENS_LOCKED_BY_JOB_ID, JIRA_ROTATION_TOKENS_LOCKED_BY_JOB_ID_TTL);
				MapRequests.put(KEY_GRAPH_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID, KEY_GRAPH_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID_TTL);
				MapRequests.put(KEY_AZURE_DEV_OPS_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID, KEY_AZURE_DEV_OPS_API_ROTATION_TOKENS_LOCKED_BY_JOB_ID_TTL);
				MapRequests.put(KEY_POST_PROCESSING_LOG_TRACKING, KEY_POST_PROCESSING_LOG_TRACKING_TTL);
				MapRequests.put(KEY_REQUEST_RELATED_SOBJECT, KEY_REQUEST_RELATED_SOBJECT_TTL);
				MapRequests.put(KEY_POST_PROCESSING_ORCHESTRATOR_LOG_TRACKING, KEY_POST_PROCESSING_ORCHESTRATOR_LOG_TRACKING_TTL);
				MapRequests.put(KEY_REQUEST_FAILED_JOB_IDS, KEY_REQUEST_FAILED_JOB_IDS_TTL);
				MapRequests.put(KEY_REQUEST_NOTIFICATION_TIMESTAMP, KEY_REQUEST_NOTIFICATION_TIMESTAMP_TTL);
			}
			return MapRequests;
		}
		private set;
	}

	private final String orgName;
	private final Map<String, String> keyMap = new Map<String, String>();

	public CacheUtils(String orgName) {
		this.orgName = orgName;
	}

	public Object getValue(String keyType) {
		if(!keyMap.containsKey(keyType)) {
			String key = buildCacheKey(keyType, this.orgName);
			keyMap.put(keyType, key);
		}
		String key = keyMap.get(keyType);
		if(isCacheAvailableForKey(keyType, key)) {
			return getCacheValue(key);
		}
		return null;
	}

	public void putValue(String keyType, Object toPut) {
		if(!keyMap.containsKey(keyType)) {
			String key = buildCacheKey(keyType, this.orgName);
			keyMap.put(keyType, key);
		}
		String key = keyMap.get(keyType);
		if(isCacheAvailableForKey(keyType, key)) {
			putCacheValue(key, toPut, getTTLValue(keyType.split(':')[0]));
		}
	}

	public static Boolean isCacheEnabled(String featureName) {
		return (MapRequests.get(featureName) != 0);
	}

	public static Integer getTTLValue(String featureName) {
		return MapRequests.get(featureName);
	}

	public static Boolean isCacheAvailableForKey(String featureName, String keyCache) {
		return (CacheUtils.isCacheEnabled(featureName)
			&& CacheUtils.isCacheAvailable
			&& CacheUtils.isCacheKeyValid(keyCache)
		);
	}

	public static Boolean isCacheAvailable {
		get {
			if (isCacheAvailable == null) {
				isCacheAvailable = false;
				Cache.OrgPartition orgPartition = getOrgPartition();
				if (orgPartition != null && orgPartition.getCapacity() >= 0) {
					try {
						orgPartition.put('TestAvailable', true);
						if (orgPartition.get('TestAvailable') != null) {
							isCacheAvailable = true;
						}
					}
					catch (Exception e) {
						// catch not available cache (skip)
					}
				}
			}
			return isCacheAvailable;
		}
		private set;
	}

	public static Boolean isCacheKeyValid(String key) {
		if(String.isNotBlank(key) && key.isAlphanumeric() && key.length() <= KEY_CACHE_LIMIT) {
			return true;
		}
		return false;
	}

	public static String buildCacheKey(String key, String orgName) {
		return buildCacheKey(key, orgName, '');
	}

	public static String buildCacheKey(String key, String orgName, String subKey) {
		return generateHash(key + orgName + subKey);
	}

	public static String generateHash(String inputString) {
		Blob targetBlob = Blob.valueOf(inputString);
		Blob hash = Crypto.generateDigest('SHA1', targetBlob);
		return EncodingUtil.convertToHex(hash);
	}

	public static Cache.OrgPartition getOrgPartition() {
		String fullPartitionName = Cache.OrgPartition.createFullyQualifiedPartition(ConfigUtil.getNameSpace(), PARTITION_NAME);
		Cache.OrgPartition orgPart = Cache.Org.getPartition(fullPartitionName);
		return orgPart;
	}

	public static void putCacheValue(String keyName, Object cacheValue, Integer ttlSecs) {
		putCacheValue(getOrgPartition(), keyName, cacheValue, ttlSecs);
	}

	public static void putCacheValue(Cache.OrgPartition orgPartition, String keyName, Object cacheValue, Integer ttlSecs) {
		if(isCacheAvailable) {
			orgPartition.put(keyName, cacheValue, ttlSecs);
		}
	}

	public static Object getCacheValue(String keyName) {
		return getCacheValue(getOrgPartition(), keyName);
	}

	public static Object getCacheValue(Cache.OrgPartition orgPartition, String keyName) {
		if(isCacheAvailable) {
			return orgPartition.get(keyName);
		}
		return null;
	}
}