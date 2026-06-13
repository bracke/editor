with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Working_Context;

package body Editor.Build_Public_Request is

   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;
   use type Editor.External_Producers.Build_Request_Provenance;

   function Trimmed (Text : Unbounded_String) return String is
   begin
      return Ada.Strings.Fixed.Trim (To_String (Text), Ada.Strings.Both);
   end Trimmed;

   function Tool_To_Build_Tool
     (Tool : Editor.Build_UI.Public_Build_Tool_Selection)
      return Editor.External_Producers.Build_Tool_Kind
   is
   begin
      case Tool is
         when Editor.Build_UI.Build_UI_No_Tool =>
            return Editor.External_Producers.No_Build_Tool;
         when Editor.Build_UI.Build_UI_GPRbuild =>
            return Editor.External_Producers.GPRbuild_Tool;
         when Editor.Build_UI.Build_UI_Alire =>
            return Editor.External_Producers.Alire_Build_Tool;
         when Editor.Build_UI.Build_UI_Custom_Disallowed_For_Now =>
            return Editor.External_Producers.Custom_Build_Tool;
      end case;
   end Tool_To_Build_Tool;

   function Program_Label_For
     (Tool : Editor.Build_UI.Public_Build_Tool_Selection) return String
   is
   begin
      case Tool is
         when Editor.Build_UI.Build_UI_GPRbuild =>
            return "gprbuild";
         when Editor.Build_UI.Build_UI_Alire =>
            return "alr";
         when others =>
            return "";
      end case;
   end Program_Label_For;

   function Convert_Arguments
     (Arguments : Editor.Build_UI.Build_UI_Argument_Vector)
      return Editor.External_Producers.Process_Argument_Vector
   is
      Result : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
   begin
      for Arg of Arguments loop
         Result.Append (Arg);
      end loop;
      return Result;
   end Convert_Arguments;

   function Build_Public_Request_From_UI_State
     (State : Editor.Build_UI.Public_Build_UI_State)
      return Public_Build_Request_Conversion_Result
   is
      Status : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
        Editor.Build_UI.Validate_Build_UI_State (State);
      Input : Editor.External_Producers.Public_Build_Command_Input;
      Request : Editor.External_Producers.Build_Run_Request;
   begin
      Input.Source := Editor.External_Producers.Public_Build_Input_User_Form;
      Input.Tool := Tool_To_Build_Tool (State.Selected_Build_Tool);
      Input.Program_Label := To_Unbounded_String
        (Program_Label_For (State.Selected_Build_Tool));
      Input.Working_Context := Editor.External_Producers.Build_Explicit_Label_Working_Context
        (Trimmed (State.Selected_Working_Context.Canonical_Path_If_Available));
      Input.Working_Context_Model :=
        (Source => Editor.External_Producers.Public_Build_Working_Context_User_Form_Label,
         Label => To_Unbounded_String
           (Editor.Build_Working_Context.Build_Working_Context_Display_Label
              (State.Selected_Working_Context)),
         User_Acknowledged_Context => True);
      Input.Arguments := Convert_Arguments (State.Structured_Arguments);
      Input.Consent :=
        (if State.Consent_Acknowledged then
            Editor.External_Producers.Build_Consent_User_Confirmed
         else
            Editor.External_Producers.Build_Consent_Not_Provided);
      Input.Consent_Model :=
        (Source =>
           (if State.Consent_Acknowledged then
               Editor.External_Producers.Public_Build_Consent_User_Form_Acknowledged
            else
               Editor.External_Producers.Public_Build_Consent_None),
         User_Acknowledged_Execution => State.Consent_Acknowledged,
         User_Acknowledged_No_Shell => State.Consent_Acknowledged,
         User_Acknowledged_External_Process => State.Consent_Acknowledged,
         User_Acknowledged_Diagnostics_Output => State.Consent_Acknowledged);
      Input.Show_Diagnostics := State.Show_Diagnostics_On_Result;

      if Status = Editor.Build_UI.Build_UI_Valid then
         Request := Editor.External_Producers.Build_Public_Build_Request_From_UI_State
           (Input);
      else
         Request :=
           (Tool => Editor.External_Producers.No_Build_Tool,
            Provenance => Editor.External_Producers.Build_Request_Unknown,
            Working_Label => Null_Unbounded_String,
            Command_Label => Null_Unbounded_String,
            Arguments => Null_Unbounded_String,
            Structured_Arguments => Editor.External_Producers.Process_Argument_Vectors.Empty_Vector);
      end if;

      return (Status => Status, Request => Request, Input => Input);
   end Build_Public_Request_From_UI_State;

   function Assert_Public_Build_Command_UX_Foundation_Coherent
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
      Conversion : constant Public_Build_Request_Conversion_Result :=
        Build_Public_Request_From_UI_State (State);
   begin
      return Editor.Build_UI.Assert_Build_UI_State_Is_Transient (State)
        and then Conversion.Status = Editor.Build_UI.Build_UI_Valid
        and then Conversion.Request.Provenance =
          Editor.External_Producers.Build_Request_From_User_Opt_In
        and then Editor.External_Producers.Process_Argument_Count
          (Conversion.Request.Structured_Arguments) =
          Editor.Build_UI.Argument_Count (State.Structured_Arguments);
   end Assert_Public_Build_Command_UX_Foundation_Coherent;


   function Assert_Public_Build_Working_Context_Foundation_Coherent
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
      Conversion : constant Public_Build_Request_Conversion_Result :=
        Build_Public_Request_From_UI_State (State);
      Working_Status : constant Editor.Build_Working_Context.Build_Working_Context_Validation_Status :=
        Editor.Build_Working_Context.Validate_Build_Working_Context
          (State.Selected_Working_Context);
   begin
      return Editor.Build_UI.Assert_Build_UI_State_Is_Transient (State)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Structured
          (State.Selected_Working_Context)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Transient
          (State.Selected_Working_Context)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Does_Not_Probe_Filesystem
          (State.Selected_Working_Context)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Persistence_Excluded
          (State.Selected_Working_Context)
        and then Working_Status = Editor.Build_Working_Context.Build_Working_Context_Valid
        and then Conversion.Status = Editor.Build_UI.Build_UI_Valid
        and then Conversion.Request.Provenance =
          Editor.External_Producers.Build_Request_From_User_Opt_In
        and then To_String (Conversion.Request.Arguments)'Length = 0
        and then Editor.External_Producers.Process_Argument_Count
          (Conversion.Request.Structured_Arguments) =
          Editor.Build_UI.Argument_Count (State.Structured_Arguments);
   end Assert_Public_Build_Working_Context_Foundation_Coherent;

end Editor.Build_Public_Request;
