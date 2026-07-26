with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Strings.Unbounded;
with Editor.Executor;
with Editor.State;

package Editor.Empty_State_Guidance.Guided_Actions is

   function Command_Suggestion_From_Descriptor
     (S       : Editor.State.State_Type;
      Command : Editor.Command_Ids.Command_Id)
      return Empty_State_Suggested_Command;

   function Stable_Name_Is_Display_Only
     (Name : String) return Boolean;

   function Suggestion_Is_Descriptor_Consistent
     (Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Suggestion_Is_Activation_Safe
     (Suggestion : Empty_State_Suggested_Command) return Boolean;

   function Suggested_Action_Availability_Label
     (Suggestion : Empty_State_Suggested_Command) return String;

   function Suggested_Action_Select_Next
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural;

   function Suggested_Action_Select_Previous
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural;

   function Suggested_Action_Selected_Index
     (Snapshot : Empty_State_Snapshot) return Natural;

   procedure Mark_Selected_Suggestion
     (Snapshot : in out Empty_State_Snapshot;
      Index    : Natural);

   function Open_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean;

   function Open_Selected_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot) return Boolean;

   function Execute_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result;

   function Activate_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result;

   function Execute_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result;

   function Activate_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result;

   function Assert_Guided_Action_Routing_Coherent
     (S : Editor.State.State_Type) return Boolean;

end Editor.Empty_State_Guidance.Guided_Actions;
