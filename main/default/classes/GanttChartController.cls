public with sharing class GanttChartController {

    public String recordId { get; set; }
    public Boolean isDev { get; set; }

    public String packageNamespace {
        get {
            return ConfigUtil.getNameSpacePrefix();
        }
        set;
    }

    public Integer userTimezoneOffset {
        get {
            return AdminService.getUserTimezoneOffset();
        }
        set;
    }

    public GanttChartController(ApexPages.StandardController stdController) {
        recordId = stdController.getId();
        String isDevParam = ApexPages.currentPage().getParameters().get('dev');
        if (String.isNotBlank(isDevParam)) {
            Cookie devCookie = new Cookie('a2developmentMode', isDevParam, null, -1, false);
            ApexPages.currentPage().setCookies(new Cookie[]{ devCookie });
            isDev = Boolean.valueOf(isDevParam);
        } else {
            Cookie devCookie = ApexPages.currentPage().getCookies().get('a2developmentMode');
            isDev = devCookie != null ? Boolean.valueOf(devCookie.getValue()) : false;
        }
    }

    @RemoteAction
    public static String remoteActionHandler(String input) {
        String result;
        RemoteActionResponse response = new RemoteActionResponse();
        String methodName;

        try {
            Map<String, Object> request = (Map<String, Object>)JSON.deserializeUntyped(input);
            response.params = request;
            String method = (String)request.get('method');
            methodName = method;
            Object data = request.get('data');
            if (method == 'getChildLogs') {
                response.data = getChildLogs(data);
            } else {
                response.error = 'Action not found';
            }
            result = JSON.serialize(response);
            Logger.getInstance().flush();
        }
        catch(Exception e) {
            response.error = e.getMessage();
            response.stack = e.getStackTraceString();
            Logger.getInstance().internalError(e, GanttChartController.class.getName(), 'remoteActionHandler' + (String.isNotBlank(methodName) ? '.' + methodName : ''));
        }
        finally {
            try {
                result = JSON.serialize(response);
            }
            catch(Exception e) {
                Logger.getInstance().internalError(e, GanttChartController.class.getName(), 'remoteActionHandler.serializeResponse');
            }
        }
        return result;
    }

    public static List<GanttChartData> getChildLogs(Object data) {
        List<GanttChartData> ganttChartData = new List<GanttChartData>();
        if (data != null) {
            String recordId = (String) JSON.deserializeUntyped(JSON.serialize(data));
            List<Log__c> logs = [
                    SELECT Id, Name, Category__c, Type__c, Summary__c, Duration__c, Created_Timestamp__c
                    FROM Log__c
                    WHERE Parent__c = :recordId
            ];
            for (Log__c log : logs) {
                ganttChartData.add(new GanttChartData(log));
            }
        }
        return ganttChartData;
    }

    public class GanttChartData {
        public String recordId;
        public String name;
        public String category;
        public String type;
        public String summary;
        public Decimal duration;
        public Decimal createdTimestamp;
        public GanttChartData(Log__c log) {
            recordId = log.Id;
            name = log.Name;
            category = log.Category__c;
            type = log.Type__c;
            summary = log.Summary__c;
            duration = log.Duration__c;
            createdTimestamp = log.Created_Timestamp__c;
        }
    }

    public class RemoteActionResponse {
        public Object params;
        public Object data;
        public String error;
        public String stack;
    }

}