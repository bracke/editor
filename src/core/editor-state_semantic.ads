with Ada.Strings.Unbounded;

package Editor.State_Semantic is

   Max_Semantic_Completion_Items : constant Natural := 12;
   subtype Semantic_Completion_Item_Index is
     Positive range 1 .. Max_Semantic_Completion_Items;

   type Semantic_Completion_Item is record
      Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Semantic_Completion_Item_Array is
     array (Semantic_Completion_Item_Index) of Semantic_Completion_Item;

   type Semantic_Popup_Kind is
     (No_Semantic_Popup,
      Semantic_Hover_Popup,
      Semantic_Completion_Popup);

   type Semantic_Popup_State is record
      Active : Boolean := False;
      Kind   : Semantic_Popup_Kind := No_Semantic_Popup;
      Anchor_Row : Natural := 0;
      Anchor_Column : Natural := 0;
      Title  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Item_Count : Natural := 0;
      Selected_Item : Natural := 0;
      Items : Semantic_Completion_Item_Array := (others => (others => <>));
   end record;

   type Quick_Fix_Workflow_State is record
      Diagnostic_Index : Natural := 0;
      Action_Index     : Natural := 0;
   end record;

end Editor.State_Semantic;
