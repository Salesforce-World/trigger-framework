/**
 * Author:Rajesh Kumar
 */

public inherited sharing virtual class TriggerConfigBase {
	@TestVisible
	private static Set < String > bypassObjectTrigger;
	@TestVisible
	public static Map < Id, Integer > beforeupdateCount {
	  get;
	  private set;
	}
	@TestVisible
	public static Map < Id, Integer > afterupdateCount {
	  get;
	  private set;
	}
	@TestVisible
	private static final String NON_TRIGGER_CONTEXT_MESSAGE = 'Invoked outside of trigger context.';
  
	// Static block to have initialization only during transaction lifecycle
	static {
	  bypassObjectTrigger = new Set < String > ();
	  beforeupdateCount = new Map < Id, Integer > (); // idtonumber count before update
	  afterupdateCount = new Map < Id, Integer > (); // idtonumber count after update
	}
	// Starting point of the framework which is invoked by Trigger in new container of instance everytime
	public void startTrigger() {
	  if (!isrunAllowed()) {
		return;
	  }
  
	  // Check context and instance type 
	  if (this.triggerContext == System.TriggerOperation.BEFORE_INSERT &&
		this instanceof TriggerContextAction.ContextAction) {
		((TriggerContextAction.ContextAction) this).beforeInsert(newList);
	  } else if (this.triggerContext == System.TriggerOperation.BEFORE_UPDATE &&
		this instanceof TriggerContextAction.ContextAction) {
		// As part of framework check how many times same id has been processed in current transaction for before update processing
		for (SObject obj: newList) {
		  if (!beforeupdateCount.containsKey(obj.id)) {
			beforeupdateCount.put(obj.id, 1);
		  } else {
			beforeupdateCount.put(obj.id, beforeupdateCount.get(obj.id) + 1);
		  }
		}
		((TriggerContextAction.ContextAction) this).beforeUpdate(newList, oldList);
	  } else if (this.triggerContext == System.TriggerOperation.AFTER_INSERT && this instanceof TriggerContextAction.ContextAction) {
		((TriggerContextAction.ContextAction) this).afterInsert(newList);
	  } else if (this.triggerContext == System.TriggerOperation.AFTER_UPDATE && this instanceof TriggerContextAction.ContextAction) {
		// As part of framework check how many times same id has been processed in current transaction for after update processing
		for (SObject obj: newList) {
		  if (!afterupdateCount.containsKey(obj.id)) {
			afterupdateCount.put(obj.id, 1);
		  } else {
			afterupdateCount.put(
			  obj.id,
			  afterupdateCount.get(obj.id) + 1
			);
		  }
		}
		((TriggerContextAction.ContextAction) this).afterUpdate(newList, oldList);
	  } else if (this.triggerContext == System.TriggerOperation.BEFORE_DELETE && this instanceof TriggerContextAction.ContextAction) {
		((TriggerContextAction.ContextAction) this).beforeDelete(oldList);
	  } else if (this.triggerContext == System.TriggerOperation.AFTER_DELETE && this instanceof TriggerContextAction.ContextAction) {
		((TriggerContextAction.ContextAction) this).afterDelete(oldList);
	  } else if (this.triggerContext == System.TriggerOperation.AFTER_UNDELETE && this instanceof TriggerContextAction.ContextAction) {
		((TriggerContextAction.ContextAction) this).afterUndelete(newList);
	  }
	}
  
	// Check if Initial Trigger run is allowed
	private Boolean isrunAllowed() {
	  if (!Trigger.isExecuting && this.triggerContext == null) {
		throw new TriggerConfigBaseException(NON_TRIGGER_CONTEXT_MESSAGE);
	  }
	  if (TriggerConfigBase.bypassObjectTrigger.contains(this.sObjectName)) {
		return false;
	  }
	  return true;
	}
  
	/*Begin Trigger ByPass Functionality */
	public static void bypassTrigger(String sObjectName) {
	  if (String.isNotBlank(sObjectName)) {
		TriggerConfigBase.bypassObjectTrigger.add(sObjectName.toLowerCase());
	  }
	}
  
	public static void clearTriggerBypass(String sObjectName) {
	  if (String.isNotBlank(sObjectName)) {
		TriggerConfigBase.bypassObjectTrigger.remove(sObjectName.toLowerCase());
	  }
	}
  
	public static Boolean isTriggerBypassed(String sObjectName) {
	  if (String.isNotBlank(sObjectName)) {
		return TriggerConfigBase.bypassObjectTrigger.contains(sObjectName.toLowerCase());
	  }
	  return false;
	}
  
	public static void clearAllTriggerBypasses() {
	  TriggerConfigBase.bypassObjectTrigger.clear();
	}
	/*End Trigger ByPass Functionality */
  
	// Class specific Instance variable to be utilized during transaction
	@TestVisible
	protected String sObjectName {
	  get {
		if (sObjectName == null) {
		  if (this.newList != null) {
			sObjectName = this.newList[0].getSObjectType().getDescribe().getName();
		  } else {
			sObjectName = this.oldList[0].getSObjectType().getDescribe().getName();
		  }
		}
		return sObjectName;
	  }
	  private set;
	}
  
	@TestVisible
	private System.TriggerOperation triggerContext {
	  get {
		if (triggerContext == null) {
		  triggerContext = Trigger.operationType;
		}
		return triggerContext;
	  }
	  set;
	}
  
	@TestVisible
	protected List < SObject > newList {
	  get {
		if (newList == null) {
		  newList = Trigger.new;
		}
		return newList;
	  }
	  private set;
	}
  
	@TestVisible
	protected List < SObject > oldList {
	  get {
		if (oldList == null) {
		  oldList = Trigger.old;
		}
		return oldList;
	  }
	  private set;
	}
	public class TriggerConfigBaseException extends Exception {
  
	}
  }