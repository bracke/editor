with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
use type Ada.Strings.Unbounded.Unbounded_String;
with Editor.Feature_Panel;
with Editor.Input_Field;

package Editor.Feature_Search_Results is

   --  Session-local, active-buffer-only Search Results feature-panel feature.
   --  This package owns query state, query input state, bounded session query
   --  history, result rows, stale-state metadata, target validation, bounded
   --  context formatting, and lifecycle cleanup. Search execution is
   --  synchronous literal matching over the current buffer snapshot.
   --
   --  Non-goals: project-wide search, inactive-buffer search, filesystem
   --  scanning, regular expressions, replace, fuzzy indexes, background
   --  workers, persisted result state/history, and LSP workspace symbols.
   --  Generic feature-panel code must remain feature-neutral and must not
   --  depend on Search Results semantics.

   type Search_Result_Id is new Natural;
   No_Search_Result : constant Search_Result_Id := 0;
   No_Buffer        : constant Natural := 0;

   type Search_Results_Feature_State is private;

   procedure Clear
     (Results : in out Search_Results_Feature_State);

   procedure Activate_Search_Query_Input
     (Results : in out Search_Results_Feature_State);

   procedure Deactivate_Search_Query_Input
     (Results : in out Search_Results_Feature_State);

   function Search_Input_Is_Active
     (Results : Search_Results_Feature_State) return Boolean;

   function Search_Input_Text
     (Results : Search_Results_Feature_State) return String;

   function Search_Input_Caret
     (Results : Search_Results_Feature_State) return Natural;

   procedure Set_Search_Input_Text
     (Results : in out Search_Results_Feature_State;
      Text    : String);

   procedure Insert_Search_Input_Character
     (Results : in out Search_Results_Feature_State;
      Ch      : Character);

   procedure Delete_Search_Input_Character_Backward
     (Results : in out Search_Results_Feature_State);

   procedure Delete_Search_Input_Character_Forward
     (Results : in out Search_Results_Feature_State);

   procedure Commit_Search_Query_To_History
     (Results : in out Search_Results_Feature_State;
      Query   : String);

   procedure Select_Previous_Search_Query
     (Results : in out Search_Results_Feature_State);

   procedure Select_Next_Search_Query
     (Results : in out Search_Results_Feature_State);

   function Search_Query_History_Count
     (Results : Search_Results_Feature_State) return Natural;

   function Search_Query_History_Item
     (Results : Search_Results_Feature_State;
      Index   : Positive) return String;

   function Case_Sensitive
     (Results : Search_Results_Feature_State) return Boolean;

   procedure Toggle_Case_Sensitive
     (Results : in out Search_Results_Feature_State);

   procedure Add_Search_Result
     (Results       : in out Search_Results_Feature_State;
      Label         : String;
      Source_Label  : String := "";
      Has_Target    : Boolean := False;
      Target_Buffer : Natural := No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
      Query         : String := "";
      Line_Text     : String := "";
      Match_Line    : Natural := 0;
      Match_Column  : Natural := 0;
      Match_Length  : Natural := 0);

   procedure Run_Active_Buffer_Search
     (Results         : in out Search_Results_Feature_State;
      Query           : String;
      Snapshot_Text   : String;
      Source_Label    : String;
      Target_Buffer   : Natural;
      Snapshot_Version : Natural := 0;
      Case_Sensitive   : Boolean := False);

   procedure Begin_External_Result_Set
     (Results      : in out Search_Results_Feature_State;
      Query        : String;
      Source_Label : String := "");

   function Best_Rerun_Selection
     (Results         : Search_Results_Feature_State;
      Previous_Buffer : Natural;
      Previous_Line   : Natural;
      Previous_Column : Natural;
      Previous_Length : Natural;
      Previous_Text   : String) return Natural;

   procedure Mark_Stale_For_Buffer_Change
     (Results         : in out Search_Results_Feature_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural := 0);

   procedure Project_Rows
     (Results : Search_Results_Feature_State;
      Panel   : in out Editor.Feature_Panel.Feature_Panel_State);

   procedure Reconcile_Search_Results_After_Row_Change
     (Results                     : in out Search_Results_Feature_State;
      Panel                       : in out Editor.Feature_Panel.Feature_Panel_State;
      Preferred_Result            : Search_Result_Id := No_Search_Result;
      Select_First_When_Available : Boolean := False);

   function Row_Count
     (Results : Search_Results_Feature_State) return Natural;

   function Is_Empty
     (Results : Search_Results_Feature_State) return Boolean;

   function Has_Query
     (Results : Search_Results_Feature_State) return Boolean;

   function Query_Text
     (Results : Search_Results_Feature_State) return String;

   function Match_Count
     (Results : Search_Results_Feature_State) return Natural;

   function Searched_Buffer
     (Results : Search_Results_Feature_State) return Natural;

   function Searched_Label
     (Results : Search_Results_Feature_State) return String;

   function Snapshot_Version
     (Results : Search_Results_Feature_State) return Natural;

   function Results_Stale
     (Results : Search_Results_Feature_State) return Boolean;

   function Header_Text
     (Results : Search_Results_Feature_State) return String;

   function Item_Id
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Search_Result_Id;

   function Item_Label
     (Results : Search_Results_Feature_State;
      Index   : Positive) return String;

   function Item_Source_Label
     (Results : Search_Results_Feature_State;
      Index   : Positive) return String;

   function Item_Has_Target
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Boolean;

   function Item_Target_Buffer
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Natural;

   function Item_Target_Line
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Natural;

   function Item_Target_Column
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Natural;

   function Item_Match_Line
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Natural;

   function Item_Match_Column
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Natural;

   function Item_Match_Length
     (Results : Search_Results_Feature_State;
      Index   : Positive) return Natural;

   function Item_Line_Text
     (Results : Search_Results_Feature_State;
      Index   : Positive) return String;

   Max_Search_Result_Context_Length : constant Natural := 80;

   function Truncate_Search_Result_Context
     (Line         : String;
      Match_Column : Natural;
      Match_Length : Natural;
      Max_Length   : Natural := Max_Search_Result_Context_Length) return String;

   function Build_Search_Result_Context
     (Line_Text    : String;
      Match_Column : Natural;
      Match_Length : Natural) return String;

   function Format_Search_Result_Label
     (Source_Label : String;
      Match_Line   : Natural;
      Match_Column : Natural;
      Match_Length : Natural;
      Line_Text    : String) return String;

   function Format_Search_Result_For_Copy
     (Results : Search_Results_Feature_State;
      Index   : Positive) return String;

   function Map_Search_Result_Row_To_Item
     (Results                        : Search_Results_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Natural;

   function Validate_Search_Result_Target
     (Results             : Search_Results_Feature_State;
      Index               : Positive;
      Active_Buffer_Token : Natural) return Boolean;

   function Validate_Row_Action
     (Results                        : Search_Results_Feature_State;
      Panel                          : Editor.Feature_Panel.Feature_Panel_State;
      Row                            : Natural;
      Expected_Projection_Generation : Natural := 0) return Boolean;

   procedure Reset_For_Buffer_Close
     (Results      : in out Search_Results_Feature_State;
      Buffer_Token : Natural);

   procedure Reset_Search_Results_For_Buffer_Close
     (Results      : in out Search_Results_Feature_State;
      Buffer_Token : Natural);

   procedure Reset_Search_Results_For_No_Active_Buffer
     (Results : in out Search_Results_Feature_State);

   procedure Reset_For_Project_Close
     (Results : in out Search_Results_Feature_State);

   procedure Reset_Search_Results_For_Project_Close
     (Results : in out Search_Results_Feature_State);

   procedure Reset_For_Workspace_Close
     (Results : in out Search_Results_Feature_State);

   procedure Reset_Search_Results_For_Workspace_Close
     (Results : in out Search_Results_Feature_State);

   procedure Assert_Search_Results_State_Consistent
     (Results : Search_Results_Feature_State);

   function Message_Search_Results_Shown return String;
   function Message_Search_Results_Cleared return String;
   function Message_No_Search_Results return String;
   function Message_No_Target return String;
   function Message_Target_Unavailable return String;
   function Message_Stale_Result return String;
   function Message_First_Result return String;
   function Message_Last_Result return String;
   function Message_Search_Repeated return String;
   function Message_Search_Query_Input_Cancelled return String;
   function Message_Search_Active_Buffer_Completed
     (Results : Search_Results_Feature_State) return String;
   function Message_Search_Active_Buffer_Empty_Query return String;
   function Message_Search_Active_Buffer_No_Active_Buffer return String;
   function Message_Search_Query_Input_Focused return String;
   function Message_Search_Repeat_No_Query return String;

private
   type Search_Result_Item is record
      Id            : Search_Result_Id := No_Search_Result;
      Label         : Ada.Strings.Unbounded.Unbounded_String;
      Source_Label  : Ada.Strings.Unbounded.Unbounded_String;
      Query         : Ada.Strings.Unbounded.Unbounded_String;
      Line_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Match_Line    : Natural := 0;
      Match_Column  : Natural := 0;
      Match_Length  : Natural := 0;
      Has_Target    : Boolean := False;
      Target_Buffer : Natural := No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
   end record;

   package Search_Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Search_Result_Item);

   package Search_Query_History_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   type Search_Results_Feature_State is record
      Rows             : Search_Result_Vectors.Vector;
      Next_Id          : Search_Result_Id := 1;
      Query_Text       : Ada.Strings.Unbounded.Unbounded_String;
      Has_Query        : Boolean := False;
      Match_Count      : Natural := 0;
      Searched_Buffer  : Natural := No_Buffer;
      Searched_Label   : Ada.Strings.Unbounded.Unbounded_String;
      Snapshot_Version : Natural := 0;
      Results_Stale    : Boolean := False;
      Search_Input_Active : Boolean := False;
      Search_Input        : Editor.Input_Field.Input_Field_State;
      Query_History       : Search_Query_History_Vectors.Vector;
      History_Cursor      : Natural := 0;
      Case_Sensitive      : Boolean := False;
   end record;

end Editor.Feature_Search_Results;
