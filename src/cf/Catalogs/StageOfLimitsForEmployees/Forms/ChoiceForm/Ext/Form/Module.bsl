////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
 
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False);

EndProcedure

#EndRegion // EventHandlers
