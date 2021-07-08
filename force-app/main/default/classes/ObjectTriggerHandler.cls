/**
 * Author:Rajesh Kumar
 */

public with sharing class ObjectTriggerHandler extends TriggerConfigBase implements TriggerContextAction.ContextAction {
	static Map < String, Boolean > permissionMap;
	static Map < String, List < Trigger_Handler__mdt >> sfobjectTohandlerMap;
	@TestVisible
	private static final String INVALID_CLASS_ERROR = 'Please check the "Trigger Handler" Custom Metadata for the class name "{0}" on the "{2}" sObject. The "{0}" class doesn\'t exist in your org apex definition.';
	@TestVisible
	private static Set < String > bypassedHandler;
  
	static {
	  bypassedHandler = new Set < String > ();
	  permissionMap = new Map < String, Boolean > ();
	  sfobjectTohandlerMap = new Map < String, List < Trigger_Handler__mdt >> ();
	}
  
	/*Begin Context Specific Method */
	public void beforeInsert(List < SObject > newList) {
	  this.invokeHandler(TriggerOperation.BEFORE_INSERT, newList, null);
	}
  
	public void afterInsert(List < SObject > newList) {
	  this.invokeHandler(TriggerOperation.AFTER_INSERT, newList, null);
	}
  
	public void beforeUpdate(List < SObject > newList, List < SObject > oldList) {
	  this.invokeHandler(TriggerOperation.BEFORE_UPDATE, newList, oldList);
	}
  
	public void afterUpdate(List < SObject > newList, List < SObject > oldList) {
	  this.invokeHandler(TriggerOperation.AFTER_UPDATE, newList, oldList);
	}
  
	public void beforeDelete(List < SObject > oldList) {
	  this.invokeHandler(TriggerOperation.BEFORE_DELETE, null, oldList);
	}
  
	public void afterDelete(List < SObject > oldList) {
	  this.invokeHandler(TriggerOperation.AFTER_DELETE, null, oldList);
	}
  
	public void afterUndelete(List < SObject > newList) {
	  this.invokeHandler(TriggerOperation.AFTER_UNDELETE, newList, null);
	}
	/*End Context Specific Method */
  
	// Method to fetch and store handler classed per objectwise 
	private list < Trigger_Handler__mdt > getHandlerAction() {
	  if (!sfobjectTohandlerMap.containsKey(this.sObjectName)) { // if data is already fetched from object then no need for more query call || iirespective of handler defined or not 
		List < Trigger_Handler__mdt > ctxActionHandler = new List < Trigger_Handler__mdt > ();
		for (Trigger_Handler__mdt actionHandler: [select Apex_Class_Name__c, Execution_Order__c, Bypass_Permission__c,
			Required_Permission__c, Trigger_Setting__r.Bypass_Permission__c, Trigger_Setting__r.Required_Permission__c
			from Trigger_Handler__mdt where Active__c = TRUE and Trigger_Setting__r.Active__c = TRUE and
			Trigger_Setting__r.Object_API_Name__c =: this.sObjectName order by Execution_Order__c ASC
		  ]) // Fetches the active handlers from metadata based on sequence 
		{
		  if (shouldHandlerExecute(actionHandler)) {
			ctxActionHandler.add(actionHandler);
		  }
		}
		sfobjectTohandlerMap.put(this.sObjectName, ctxActionHandler);
	  }
	  return sfobjectTohandlerMap.get(this.sObjectName);
	}
  
	// Check Eligibility to run trigger & handler based on permission defined 
	@TestVisible
	private Boolean shouldHandlerExecute(Trigger_Handler__mdt handlerMetadata) {
	  String triggerBypassPname = handlerMetadata.Trigger_Setting__r.ByPass_Permission__c;
	  String triggerRequiredPname = handlerMetadata.Trigger_Setting__r.Required_Permission__c;
	  for (String permissionName: new List < String > {
		  handlerMetadata.Bypass_Permission__c,
		  handlerMetadata.Required_Permission__c,
		  triggerBypassPname,
		  triggerRequiredPname
		}) {
		if (permissionName != null && !permissionMap.containsKey(permissionName)) {
		  permissionMap.put(permissionName, FeatureManagement.checkPermission(permissionName));
		}
	  }
	  Boolean handlerShouldExecute = !((handlerMetadata.Bypass_Permission__c != null && permissionMap.get(handlerMetadata.Bypass_Permission__c)) || (handlerMetadata.Required_Permission__c != null &&
		!permissionMap.get(handlerMetadata.Required_Permission__c)));
	  Boolean sObjectShouldExecute = !((triggerBypassPname != null && permissionMap.get(triggerBypassPname)) || (triggerRequiredPname != null && !permissionMap.get(triggerRequiredPname)));
	  return handlerShouldExecute && sObjectShouldExecute;
	}
	@TestVisible
	private List<Trigger_Handler__mdt> handlerMetadata {
		get {
			if (handlerMetadata == null) {
				handlerMetadata = getHandlerAction();
			}
			return handlerMetadata;
		}
		set;
	}
	// Invoke handler functions to cpuple implemented handler with context specific method 
	private void invokeHandler(TriggerOperation context, List < SObject > newList, List < SObject > oldList) {
	//   List < Trigger_Handler__mdt > handlerMetadata = getHandlerAction();
	  for (Trigger_Handler__mdt handlerMdt: handlerMetadata) {
		Object TriggerContextAction;
		Try {
		  TriggerContextAction = Type.forName(handlerMdt.Apex_Class_Name__c).newInstance();
		}
		Catch(System.NullPointerException e) {
		  handleException(INVALID_CLASS_ERROR, handlerMdt.Apex_Class_Name__c, context);
		}
		if (!ObjectTriggerHandler.isHandlerBypassed(handlerMdt.Apex_Class_Name__c) && !TriggerConfigBase.isTriggerBypassed(this.sObjectName)) {
		  if (context == TriggerOperation.BEFORE_INSERT) {
			((TriggerContextAction.ContextAction) TriggerContextAction).beforeInsert(newList);
		  } else if (context == TriggerOperation.AFTER_INSERT) {
			((TriggerContextAction.ContextAction) TriggerContextAction).afterInsert(newList);
		  } else if (context == TriggerOperation.BEFORE_UPDATE) {
			((TriggerContextAction.ContextAction) TriggerContextAction).beforeUpdate(newList, oldList);
		  } else if (context == TriggerOperation.AFTER_UPDATE) {
			((TriggerContextAction.ContextAction) TriggerContextAction).afterUpdate(newList, oldList);
		  } else if (context == TriggerOperation.BEFORE_DELETE) {
			((TriggerContextAction.ContextAction) TriggerContextAction).beforeDelete(oldList);
		  } else if (context == TriggerOperation.AFTER_DELETE) {
			((TriggerContextAction.ContextAction) TriggerContextAction).afterDelete(oldList);
		  } else if (context == TriggerOperation.AFTER_UNDELETE) {
			((TriggerContextAction.ContextAction) TriggerContextAction).afterUndelete(newList);
		  }
		}
	  }
	}
  
	// @TODO : To be tested 	  
	private void handleException(String error, String className, TriggerOperation triggerOperation) {
	  throw new ObjectTriggerHandlerException(
		String.format(error, new List < String > {className,String.valueOf(triggerOperation),this.sObjectName}));
	}
	/**Begin Utility for Handler/Helper specific bypass */
	public static void bypassHandler(String handlerName) {
	  if (String.isNotBlank(handlerName)) {
		ObjectTriggerHandler.bypassedHandler.add(handlerName.toLowerCase());
	  }
	}
  
	public static void clearHandlerBypass(String handlerName) {
	  if (String.isNotBlank(handlerName)) {
		ObjectTriggerHandler.bypassedHandler.remove(handlerName.toLowerCase());
	  }
	}
  
	public static Boolean isHandlerBypassed(String handlerName) {
	  if (String.isNotBlank(handlerName)) {
		return ObjectTriggerHandler.bypassedHandler.contains(handlerName.toLowerCase());
	  }
	  return false;
	}
  
	public static void clearAllHandlerBypasses() {
	  ObjectTriggerHandler.bypassedHandler.clear();
	}
	/**End Utility for Handler/Helper specific bypass */
  
	class ObjectTriggerHandlerException extends Exception {}
  }