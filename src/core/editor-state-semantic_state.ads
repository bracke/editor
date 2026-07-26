with Editor.State_Semantic;

package Editor.State.Semantic_State is

   Max_Semantic_Completion_Items : constant Natural :=
     Editor.State_Semantic.Max_Semantic_Completion_Items;
   subtype Semantic_Completion_Item_Index is
     Editor.State_Semantic.Semantic_Completion_Item_Index;
   subtype Semantic_Completion_Item is
     Editor.State_Semantic.Semantic_Completion_Item;
   subtype Semantic_Completion_Item_Array is
     Editor.State_Semantic.Semantic_Completion_Item_Array;

   subtype Semantic_Popup_Kind is Editor.State_Semantic.Semantic_Popup_Kind;
   No_Semantic_Popup : constant Semantic_Popup_Kind :=
     Editor.State_Semantic.No_Semantic_Popup;
   Semantic_Hover_Popup : constant Semantic_Popup_Kind :=
     Editor.State_Semantic.Semantic_Hover_Popup;
   Semantic_Completion_Popup : constant Semantic_Popup_Kind :=
     Editor.State_Semantic.Semantic_Completion_Popup;

   subtype Semantic_Popup_State is Editor.State_Semantic.Semantic_Popup_State;
   subtype Quick_Fix_Workflow_State is
     Editor.State_Semantic.Quick_Fix_Workflow_State;

end Editor.State.Semantic_State;
