@RestResource(urlMapping='/chargify/*')
global with sharing class ChargifyRestService {

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        System.debug('---'+json.serialize(req));
        System.debug('---' + req.requestBody.toString());
        System.debug('---1-'+JSON.serialize(RestContext.request.params));
        System.debug('---2-'+JSON.serialize(RestContext.request.params.keySet()));

        res.responseBody = Blob.valueOf('OK');
        res.statusCode = 200;

    
    }

    @HttpGet
    global static void doGet() {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
        try {
            //GetLogResult result = new GetLogResult();
            Blob responseData = null;
            System.debug('---'+json.serialize(req));
    
            Map<String, String> params = (req != null && req.params != null) ? req.params : new Map<String, String>();
            
            Integer i = 10/0;
            String param1 = (String)req.params.get('param1');
            //result = new GetLogResult(params);
            //responseData = Blob.valueOf(JSON.serialize(result));
    
            res.responseBody = Blob.valueOf('OK');//responseData;
            res.statusCode = 200;//result.statusCode;
        }
        catch(Exception e) {
            Log.instance.addRestIntegrationError(Log.Area.OpportunityManagement, e, req, res);
            Log.instance.flush();
        }
    }
}