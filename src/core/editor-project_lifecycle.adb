with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Project_Lifecycle is


   function Is_Project_Opening_Transition
     (Transition : Project_Lifecycle_Transition) return Boolean
   is
   begin
      return Transition in Open_Project_Lifecycle_Transition
         | Open_Recent_Project_Lifecycle_Transition
         | Switch_Project_Lifecycle_Transition
         | Reset_Project_Lifecycle_Transition;
   end Is_Project_Opening_Transition;

   function Is_Project_Closing_Transition
     (Transition : Project_Lifecycle_Transition) return Boolean
   is
   begin
      return Transition in Close_Project_Lifecycle_Transition
         | Clear_Project_Context_Lifecycle_Transition;
   end Is_Project_Closing_Transition;

   function Requires_Dirty_Guard
     (Transition : Project_Lifecycle_Transition) return Boolean
   is
   begin
      return Transition in Open_Project_Lifecycle_Transition
         | Open_Recent_Project_Lifecycle_Transition
         | Switch_Project_Lifecycle_Transition
         | Reset_Project_Lifecycle_Transition
         | Close_Project_Lifecycle_Transition
         | Clear_Project_Context_Lifecycle_Transition
         | Restore_Workspace_Lifecycle_Transition;
   end Requires_Dirty_Guard;

   function Resets_Project_Scoped_State
     (Transition : Project_Lifecycle_Transition) return Boolean
   is
   begin
      return Transition in Open_Project_Lifecycle_Transition
         | Open_Recent_Project_Lifecycle_Transition
         | Switch_Project_Lifecycle_Transition
         | Reset_Project_Lifecycle_Transition
         | Close_Project_Lifecycle_Transition
         | Clear_Project_Context_Lifecycle_Transition
         | Restore_Workspace_Lifecycle_Transition;
   end Resets_Project_Scoped_State;

   function Count_Text
     (Count    : Natural;
      Singular : String;
      Plural   : String) return String
   is
   begin
      if Count = 1 then
         return "1 " & Singular;
      end if;
      return Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both)
        & " " & Plural;
   end Count_Text;

   procedure Append_Part
     (Parts : in out Unbounded_String;
      Text  : String)
   is
   begin
      if Length (Parts) > 0 then
         Append (Parts, ", ");
      end if;
      Append (Parts, Text);
   end Append_Part;

   function Summary_Text
     (Result : Project_Lifecycle_Result) return String
   is
      Parts : Unbounded_String := Null_Unbounded_String;
   begin
      if Result.Dirty_Buffers_Blocked > 0 then
         return "Project lifecycle blocked: "
           & Count_Text
               (Result.Dirty_Buffers_Blocked,
                "unsaved buffer",
                "unsaved buffers");
      end if;

      if Result.Project_Closed then
         Append_Part (Parts, "Project closed");
      elsif Result.Project_Changed then
         Append_Part (Parts, "Project changed");
      end if;

      if Result.Buffers_Closed > 0 then
         Append_Part
           (Parts,
            Count_Text
              (Result.Buffers_Closed, "buffer closed", "buffers closed"));
      end if;

      if Result.Project_State_Reset then
         Append_Part (Parts, "project state reset");
      end if;

      if Result.Recent_Project_Promoted then
         Append_Part (Parts, "recent project updated");
      end if;

      if Result.Workspace_State_Restored then
         Append_Part (Parts, "workspace state restored");
      end if;

      if Length (Parts) = 0 then
         return "No project lifecycle changes";
      end if;

      return To_String (Parts);
   end Summary_Text;

end Editor.Project_Lifecycle;
