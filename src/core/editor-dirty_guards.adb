with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;

package body Editor.Dirty_Guards is

   function Count_Image (Count : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both);
   end Count_Image;

   function Allowed
     (Summary : Dirty_Buffer_Summary) return Dirty_Transition_Result
   is
   begin
      return (Status  => Dirty_Transition_Allowed,
              Summary => Summary,
              Reason  => Null_Unbounded_String);
   end Allowed;

   function Blocked
     (Summary : Dirty_Buffer_Summary;
      Reason  : String) return Dirty_Transition_Result
   is
   begin
      return (Status  => Dirty_Transition_Blocked,
              Summary => Summary,
              Reason  => To_Unbounded_String (Reason));
   end Blocked;

   function Is_Allowed
     (Result : Dirty_Transition_Result) return Boolean
   is
   begin
      return Result.Status = Dirty_Transition_Allowed;
   end Is_Allowed;

   function Reason
     (Result : Dirty_Transition_Result) return String
   is
   begin
      return To_String (Result.Reason);
   end Reason;

   function Dirty_Buffer_Count_Text
     (Summary : Dirty_Buffer_Summary) return String
   is
   begin
      if Summary.Dirty_Count = 1 then
         return "1 unsaved buffer";
      else
         return Count_Image (Summary.Dirty_Count) & " unsaved buffers";
      end if;
   end Dirty_Buffer_Count_Text;

   function No_Unsaved_Changes_Message return String is
   begin
      return "No unsaved changes";
   end No_Unsaved_Changes_Message;

   function No_Dirty_File_Backed_Buffers_Message return String is
   begin
      return "No dirty file-backed buffers";
   end No_Dirty_File_Backed_Buffers_Message;

   function No_Clean_Buffers_Message return String is
   begin
      return "No clean buffers";
   end No_Clean_Buffers_Message;

   function No_Pending_Transition_Message return String is
   begin
      return "No pending transition";
   end No_Pending_Transition_Message;

   function Save_Or_Resolve_Changes_First_Message return String is
   begin
      return "Save or resolve changes first";
   end Save_Or_Resolve_Changes_First_Message;

   function Pending_Transition_Canceled_Message return String is
   begin
      return "Pending transition canceled";
   end Pending_Transition_Canceled_Message;

   function Pending_Transition_No_Longer_Valid_Message return String is
   begin
      return "Pending transition is no longer valid";
   end Pending_Transition_No_Longer_Valid_Message;

   function Workspace_State_Saved_Message return String is
   begin
      return "Workspace state saved";
   end Workspace_State_Saved_Message;

   function Workspace_State_Restored_Message return String is
   begin
      return "Workspace restored.";
   end Workspace_State_Restored_Message;

   function Guard_Transition
     (Kind    : Dirty_Transition_Kind;
      Summary : Dirty_Buffer_Summary) return Dirty_Transition_Result
   is
   begin
      if Summary.Dirty_Count = 0 then
         return Allowed (Summary);
      end if;

      case Kind is
         when Close_Buffer_Transition =>
            return Blocked
              (Summary,
               "Dirty buffer cannot be closed");
         when Close_All_Buffers_Transition =>
            return Blocked (Summary, Save_Or_Resolve_Changes_First_Message);
         when Close_Project_Transition | Clear_Project_Transition =>
            return Blocked (Summary, "Cannot close project with unsaved changes");
         when Open_Project_Transition | Switch_Project_Transition | Open_Recent_Project_Transition =>
            return Blocked
              (Summary, "Cannot switch project with unsaved changes");
         when Restore_Workspace_Transition =>
            return Blocked
              (Summary, "Cannot restore workspace with unsaved changes");
      end case;
   end Guard_Transition;

end Editor.Dirty_Guards;
