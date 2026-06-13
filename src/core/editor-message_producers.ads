with Editor.Feature_Messages;
with Editor.Producer_Contracts;
with Editor.State;

package Editor.Message_Producers is

   subtype Message_Severity is Editor.Feature_Messages.Message_Severity;
   subtype Message_Source_Kind is Editor.Feature_Messages.Message_Source_Kind;
   subtype Producer_Result is Editor.Producer_Contracts.Producer_Result;
   subtype Producer_Result_Status is Editor.Producer_Contracts.Producer_Result_Status;

   function Normalize_Message_Source (Source : String) return String;

   function Post_Message_With_Result
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String := "";
      Kind     : Message_Source_Kind := Editor.Feature_Messages.Unknown_Source)
      return Producer_Result;

   function Post_Targeted_Message_With_Result
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String;
      Kind     : Message_Source_Kind;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural) return Producer_Result;

   procedure Post_Message
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String := "";
      Kind     : Message_Source_Kind := Editor.Feature_Messages.Unknown_Source);

   procedure Post_Targeted_Message
     (State    : in out Editor.State.State_Type;
      Severity : Message_Severity;
      Text     : String;
      Source   : String;
      Kind     : Message_Source_Kind;
      Buffer   : Natural;
      Line     : Natural;
      Column   : Natural);

end Editor.Message_Producers;
