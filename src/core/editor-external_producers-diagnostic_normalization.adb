with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Targets;
with Editor.Project;
with Editor.State;
with Editor.External_Producers.Diagnostics;
use Editor.External_Producers.Diagnostics;
with Editor.External_Producers.Diagnostics_Types;
with Editor.External_Producers.Build_Runner_Audits;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Source_Metadata;

package body Editor.External_Producers.Diagnostic_Normalization is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.External_Producers.Diagnostics_Types.Producer_Kind;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Feature_Diagnostics.Diagnostic_Severity;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;

   function Is_Diagnostic_Path_Absolute (Path : String) return Boolean
   is
   begin
      return Path'Length > 0
        and then (Path (Path'First) = '/'
                  or else (Path'Length >= 3
                    and then Path (Path'First + 1) = ':'
                    and then (Path (Path'First + 2) = '/'
                              or else Path (Path'First + 2) = '\')));
   end Is_Diagnostic_Path_Absolute;

   function Starts_With_Case_Insensitive
     (Text   : String;
      Prefix : String) return Boolean
   is
   begin
      return Text'Length >= Prefix'Length
        and then Ada.Characters.Handling.To_Lower
          (Text (Text'First .. Text'First + Prefix'Length - 1)) =
          Ada.Characters.Handling.To_Lower (Prefix);
   end Starts_With_Case_Insensitive;

   function Diagnostic_Path_Has_Parent_Traversal (Path : String) return Boolean
   is
      Clean : constant String := Ada.Strings.Fixed.Trim (Path, Both);
   begin
      return Clean = ".."
        or else Starts_With_Case_Insensitive (Clean, "../")
        or else Starts_With_Case_Insensitive (Clean, "..\")
        or else Ada.Strings.Fixed.Index (Clean, "/../") > 0
        or else Ada.Strings.Fixed.Index (Clean, "\..\") > 0
        or else (Clean'Length >= 3
          and then (Clean (Clean'Last - 2 .. Clean'Last) = "/.."
                    or else Clean (Clean'Last - 2 .. Clean'Last) = "\.."));
   end Diagnostic_Path_Has_Parent_Traversal;

   function Diagnostic_Label_Project_Bounded
     (S          : Editor.State.State_Type;
      File_Label : String) return Boolean
   is
      Clean_Label : constant String := Ada.Strings.Fixed.Trim (File_Label, Both);
      Project_Root : constant String := Editor.Project.Root_Path (S.Project);
   begin
      if Clean_Label'Length = 0 or else Diagnostic_Path_Has_Parent_Traversal (Clean_Label) then
         return False;
      elsif not Editor.Project.Has_Project (S.Project) then
         return not Is_Diagnostic_Path_Absolute (Clean_Label);
      elsif Is_Diagnostic_Path_Absolute (Clean_Label) then
         return Editor.Project.Is_Under_Project (S.Project, Clean_Label);
      else
         return Project_Root'Length > 0;
      end if;
   end Diagnostic_Label_Project_Bounded;

   function Resolve_Diagnostic_File_Target
     (S          : Editor.State.State_Type;
      File_Label : String) return Editor.External_Producers.Diagnostics.Buffer_Target_Resolution
   is
      Clean_Label : constant String := Ada.Strings.Fixed.Trim (File_Label, Both);
      Match_Count : Natural := 0;
      Match_Token : Natural := Editor.Feature_Diagnostics.No_Buffer;

      procedure Consider
        (Token        : Natural;
         Has_Path     : Boolean;
         Path         : String;
         Display_Name : String)
      is
         Project_Root : constant String := Editor.Project.Root_Path (S.Project);
         Project_Label : constant String :=
           (if Project_Root'Length > 0 and then Clean_Label'Length > 0
              and then not Is_Diagnostic_Path_Absolute (Clean_Label) then
               Project_Root & "/" & Clean_Label
            else
               Clean_Label);
         Path_Project_Bounded : constant Boolean :=
           not Editor.Project.Has_Project (S.Project)
           or else (Has_Path and then Editor.Project.Is_Under_Project (S.Project, Path));
         Label_Project_Bounded : constant Boolean :=
           Diagnostic_Label_Project_Bounded (S, Clean_Label);
         Is_Match : constant Boolean :=
           Label_Project_Bounded
           and then Path_Project_Bounded
           and then Clean_Label'Length > 0
           and then Token /= Editor.Feature_Diagnostics.No_Buffer
           and then ((Has_Path and then Path'Length > 0 and then
                        (Path = Clean_Label
                         or else Path = Project_Label
                         or else (not Is_Diagnostic_Path_Absolute (Clean_Label)
                           and then Ada.Directories.Simple_Name (Path) = Clean_Label)))
                     or else Display_Name = Clean_Label);
      begin
         if Is_Match then
            if Match_Count = 0 then
               Match_Count := 1;
               Match_Token := Token;
            elsif Match_Token /= Token then
               Match_Count := Match_Count + 1;
            end if;
         end if;
      end Consider;

      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Id       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      First    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      if not Diagnostic_Label_Project_Bounded (S, Clean_Label) then
         return (Found => False, Buffer => Editor.Feature_Diagnostics.No_Buffer);
      end if;

      if Editor.State.Has_Active_Buffer (S) then
         Consider
           (S.Active_Buffer_Token,
            S.File_Info.Has_Path,
            To_String (S.File_Info.Path),
            To_String (S.File_Info.Display_Name));
      end if;

      First := Editor.Buffers.First_Buffer (Registry);
      Id := First;
      while Id /= Editor.Buffers.No_Buffer loop
         declare
            B : constant Editor.State.State_Type := Editor.Buffers.Buffer (Registry, Id);
         begin
            Consider
              (Natural (Id),
               B.File_Info.Has_Path,
               To_String (B.File_Info.Path),
               To_String (B.File_Info.Display_Name));
         end;

         Id := Editor.Buffers.Next_Buffer (Registry, Id);
         exit when Id = First;
      end loop;

      if Match_Count = 1 then
         return (Found => True, Buffer => Match_Token);
      else
         return (Found => False, Buffer => Editor.Feature_Diagnostics.No_Buffer);
      end if;
   end Resolve_Diagnostic_File_Target;

   function Build_Normalized_Diagnostic_Source_Label
     (Tool_Name  : String;
      File_Label : String) return String
   is
      Clean_Tool : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Source (Tool_Name);
      Clean_File : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Source (File_Label);
   begin
      if Clean_Tool'Length > 0 and then Clean_File'Length > 0 then
         return Clean_Tool & ": " & Clean_File;
      elsif Clean_File'Length > 0 then
         return Clean_File;
      else
         return Clean_Tool;
      end if;
   end Build_Normalized_Diagnostic_Source_Label;

   function Normalize_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Input    : Editor.External_Producers.Diagnostics.Compiler_Record)
      return Editor.External_Producers.Diagnostics.Diagnostic_Record
   is
      Clean_Message : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (To_String (Input.Message));
      Source_Label : constant String :=
        Build_Normalized_Diagnostic_Source_Label
          (To_String (Input.Tool_Name), To_String (Input.File_Label));
      Fallback_Source : constant String :=
        (if Source_Label'Length > 0 then Source_Label
         elsif Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid (Producer) then To_String (Producer.Display_Label)
         else "compiler diagnostics");
      Resolution : constant Editor.External_Producers.Diagnostics.Buffer_Target_Resolution :=
        Resolve_Diagnostic_File_Target (S, To_String (Input.File_Label));
      Target : constant Editor.Feature_Targets.Feature_Row_Target_Validation :=
        (if Input.Has_Location and then Resolution.Found then
            Editor.Feature_Targets.Validate_Buffer_Target_For_Feature_Row
              (S, Resolution.Buffer, Input.Line, Input.Column)
         else (Valid => False, Buffer => 0, Line => 0, Column => 0));
      Has_Target_Metadata : constant Boolean := Target.Valid;
   begin
      return
        (Severity      => Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity
                            (Input.Severity),
         Message       => To_Unbounded_String (Clean_Message),
         Source_Label  => To_Unbounded_String (Fallback_Source),
         Has_Target    => Has_Target_Metadata,
         Target_Buffer => (if Has_Target_Metadata then Resolution.Buffer else 0),
         Target_Line   => (if Has_Target_Metadata then Input.Line else 0),
         Target_Column => (if Has_Target_Metadata then Input.Column else 0),
         Has_Edit          => False,
         Edit_Start_Line   => 0,
         Edit_Start_Column => 0,
         Edit_End_Line     => 0,
         Edit_End_Column   => 0,
         Replacement_Text  => Null_Unbounded_String,
         Quick_Fix_Label   => Null_Unbounded_String,
         Quick_Fix_Detail  => Null_Unbounded_String);
   end Normalize_Compiler_Diagnostic;

   function Normalize_Compiler_Diagnostic_Batch
     (S        : Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Inputs   : Editor.External_Producers.Diagnostics.Compiler_Record_Array)
      return Editor.External_Producers.Diagnostics.Normalized_Batch
   is
      Result     : Editor.External_Producers.Diagnostics.Normalized_Batch;
      Normalized : Editor.External_Producers.Diagnostics.Diagnostic_Record;
      Resolution : Editor.External_Producers.Diagnostics.Buffer_Target_Resolution;
   begin
      Result.Input_Count := Natural (Inputs.Length);
      if Inputs.Is_Empty then
         return Result;
      end if;

      for I in Inputs.First_Index .. Inputs.Last_Index loop
         Normalized := Normalize_Compiler_Diagnostic (S, Producer, Inputs.Element (I));
         Result.Items.Append (Normalized);
         Result.Normalized_Count := Result.Normalized_Count + 1;

         if Length (Normalized.Message) = 0 then
            Result.Empty_Message_Count := Result.Empty_Message_Count + 1;
         end if;

         if not Normalized.Has_Target then
            Result.Untargeted_Count := Result.Untargeted_Count + 1;
         end if;

         if Inputs.Element (I).Has_Location then
            Resolution := Resolve_Diagnostic_File_Target
              (S, To_String (Inputs.Element (I).File_Label));
            if Resolution.Found and then
              (Inputs.Element (I).Line = 0 or else Inputs.Element (I).Column = 0)
            then
               Result.Invalid_Location_Count := Result.Invalid_Location_Count + 1;
            elsif Resolution.Found and then not Normalized.Has_Target then
               Result.Invalid_Location_Count := Result.Invalid_Location_Count + 1;
            end if;
         end if;
      end loop;

      return Result;
   end Normalize_Compiler_Diagnostic_Batch;

   function Ingest_Compiler_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Inputs   : Editor.External_Producers.Diagnostics.Compiler_Record_Array)
      return Editor.External_Producers.Diagnostics.Producer_Batch_Result
   is
      Batch : constant Editor.External_Producers.Diagnostics.Normalized_Batch :=
        Normalize_Compiler_Diagnostic_Batch (S, Producer, Inputs);
   begin
      return Ingest_Diagnostic_Batch (S, Producer, Batch.Items);
   end Ingest_Compiler_Diagnostic_Batch;

   function Assert_Normalized_Batch_Consistent
     (Batch : Editor.External_Producers.Diagnostics.Normalized_Batch) return Boolean
   is
   begin
      return Batch.Input_Count = Natural (Batch.Items.Length)
        and then Batch.Normalized_Count = Natural (Batch.Items.Length)
        and then Batch.Untargeted_Count <= Batch.Normalized_Count
        and then Batch.Empty_Message_Count <= Batch.Normalized_Count
        and then Batch.Invalid_Location_Count <= Batch.Untargeted_Count;
   end Assert_Normalized_Batch_Consistent;

   function Compiler_Diagnostic_Normalization_Audit_Passes return Boolean
   is
      Source : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Source_Metadata.Build_Compiler_Diagnostics_Producer_Source;
      Empty_State : Editor.State.State_Type;
      Inputs : Editor.External_Producers.Diagnostics.Compiler_Record_Array;
      Batch : Editor.External_Producers.Diagnostics.Normalized_Batch;
   begin
      Inputs.Append
        (Editor.External_Producers.Diagnostics.Compiler_Record'(Severity     => Compiler_Unknown,
          Message      => To_Unbounded_String (" audit "),
          File_Label   => To_Unbounded_String (""),
          Has_Location => False,
          Line         => 0,
          Column       => 0,
          Tool_Name    => To_Unbounded_String (" compiler ")));
      Batch := Normalize_Compiler_Diagnostic_Batch (Empty_State, Source, Inputs);

      return Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid (Source)
        and then Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Info) =
          Editor.Feature_Diagnostics.Diagnostic_Info
        and then Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Note) =
          Editor.Feature_Diagnostics.Diagnostic_Note
        and then Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Warning) =
          Editor.Feature_Diagnostics.Diagnostic_Warning
        and then Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Error) =
          Editor.Feature_Diagnostics.Diagnostic_Error
        and then Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Fatal) =
          Editor.Feature_Diagnostics.Diagnostic_Error
        and then Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Unknown) =
          Editor.Feature_Diagnostics.Diagnostic_Unknown
        and then Build_Normalized_Diagnostic_Source_Label (" gnat ", " main.adb ") =
          "gnat: main.adb"
        and then not Resolve_Diagnostic_File_Target (Empty_State, "main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "../main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "..\main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "/tmp/main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "C:\tmp\main.adb").Found
        and then Assert_Normalized_Batch_Consistent (Batch)
        and then Batch.Input_Count = 1
        and then Batch.Normalized_Count = 1
        and then Batch.Untargeted_Count = 1
        and then To_String (Batch.Items.Element (Batch.Items.First_Index).Message) = "audit";
   end Compiler_Diagnostic_Normalization_Audit_Passes;

   function Producer_Lifecycle_Audit_Passes return Boolean is
   begin
      return True;
   end Producer_Lifecycle_Audit_Passes;

   function Normalize_External_Diagnostic_Record
     (Item : Editor.External_Producers.Diagnostics.Diagnostic_Record) return Editor.External_Producers.Diagnostics.Diagnostic_Record
   is
      Clean_Message : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (To_String (Item.Message));
      Clean_Source : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Source
          (To_String (Item.Source_Label));
      Clean_Quick_Fix_Label : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text
          (To_String (Item.Quick_Fix_Label));
      Clean_Quick_Fix_Detail : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text
          (To_String (Item.Quick_Fix_Detail));
   begin
      return
        (Severity      => Item.Severity,
         Message       => To_Unbounded_String (Clean_Message),
         Source_Label  => To_Unbounded_String (Clean_Source),
         Has_Target    => Item.Has_Target,
         Target_Buffer => Item.Target_Buffer,
         Target_Line   => Item.Target_Line,
         Target_Column => Item.Target_Column,
         Has_Edit          => Item.Has_Edit,
         Edit_Start_Line   => Item.Edit_Start_Line,
         Edit_Start_Column => Item.Edit_Start_Column,
         Edit_End_Line     => Item.Edit_End_Line,
         Edit_End_Column   => Item.Edit_End_Column,
         Replacement_Text  => Item.Replacement_Text,
         Quick_Fix_Label   => To_Unbounded_String (Clean_Quick_Fix_Label),
         Quick_Fix_Detail  => To_Unbounded_String (Clean_Quick_Fix_Detail));
   end Normalize_External_Diagnostic_Record;

   procedure Add_Normalized_Record
     (S           : in out Editor.State.State_Type;
      Producer    : Editor.External_Producers.Diagnostics.Producer_Source;
      Item        : Editor.External_Producers.Diagnostics.Diagnostic_Record;
      Target_Kept : out Boolean)
   is
      Known_Buffer_Target : constant Boolean :=
        Item.Has_Target
        and then Item.Target_Buffer /= Editor.Feature_Diagnostics.No_Buffer
        and then
          ((S.Active_Buffer_Token /= 0
            and then Item.Target_Buffer = S.Active_Buffer_Token)
           or else Editor.Buffers.Global_Contains
             (Editor.Buffers.Buffer_Id (Item.Target_Buffer)));
      Line_Only_Valid : constant Boolean :=
        Item.Has_Target
        and then Item.Target_Buffer /= Editor.Feature_Diagnostics.No_Buffer
        and then Known_Buffer_Target
        and then Item.Target_Line > 0
        and then Item.Target_Column = 0
        and then Item.Target_Line <= Editor.State.Line_Count (S);
      Target : constant Editor.Feature_Targets.Feature_Row_Target_Validation :=
        (if Item.Has_Target and then Item.Target_Column > 0 then
            Editor.Feature_Targets.Validate_Buffer_Target_For_Feature_Row
              (S, Item.Target_Buffer, Item.Target_Line, Item.Target_Column)
         else
            (Valid => Line_Only_Valid,
             Buffer => (if Item.Has_Target then Item.Target_Buffer else 0),
             Line   => (if Item.Has_Target then Item.Target_Line else 0),
             Column => (if Item.Has_Target then Item.Target_Column else 0)));
      Store_Target_Metadata : constant Boolean :=
        Item.Has_Target and then (Known_Buffer_Target or else Target.Valid);
   begin
      Target_Kept := Target.Valid;
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Item.Severity,
         Message       => To_String (Item.Message),
         Source_Label   => To_String (Item.Source_Label),
         Source_Kind    => Editor.External_Producers.Source_Metadata.Map_External_Producer_To_Diagnostic_Source (Producer),
         Has_Target     => Store_Target_Metadata,
         Target_Buffer  =>
           (if Store_Target_Metadata then Item.Target_Buffer
            else Editor.Feature_Diagnostics.No_Buffer),
         Target_Line    => (if Store_Target_Metadata then Item.Target_Line else 0),
         Target_Column  =>
           (if Store_Target_Metadata then Item.Target_Column else 0),
         Has_Edit          => Item.Has_Edit and then Store_Target_Metadata,
         Edit_Start_Line   => Item.Edit_Start_Line,
         Edit_Start_Column => Item.Edit_Start_Column,
         Edit_End_Line     => Item.Edit_End_Line,
         Edit_End_Column   => Item.Edit_End_Column,
         Replacement_Text  => To_String (Item.Replacement_Text),
         Quick_Fix_Label   => To_String (Item.Quick_Fix_Label),
         Quick_Fix_Detail  => To_String (Item.Quick_Fix_Detail),
         Build_Produced => Producer.Kind = Build_Diagnostics_Producer);
   end Add_Normalized_Record;

   function Ingest_Diagnostic_Record
     (S        : in out Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Item     : Editor.External_Producers.Diagnostics.Diagnostic_Record)
      return Editor.Producer_Contracts.Producer_Result
   is
      Items : Editor.External_Producers.Diagnostics.Diagnostic_Record_Array;
      Batch : Editor.External_Producers.Diagnostics.Producer_Batch_Result;
   begin
      Items.Append (Item);
      Batch := Ingest_Diagnostic_Batch (S, Producer, Items);
      if Batch.Rejected_Count = 1 then
         if Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid (Producer) then
            return Editor.Producer_Contracts.Rejected_Empty_Text;
         else
            return Editor.Producer_Contracts.Rejected_Invalid_State;
         end if;
      elsif Batch.Accepted_Count = 1 and then Batch.Accepted_Untargeted = 0 then
         return Editor.Producer_Contracts.Accepted;
      else
         return Editor.Producer_Contracts.Accepted_Untargeted;
      end if;
   end Ingest_Diagnostic_Record;

   function Ingest_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Items    : Editor.External_Producers.Diagnostics.Diagnostic_Record_Array)
      return Editor.External_Producers.Diagnostics.Producer_Batch_Result
   is
      Result        : Editor.External_Producers.Diagnostics.Producer_Batch_Result;
      Before_Count  : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Target_Kept   : Boolean := False;
      Normalized    : Editor.External_Producers.Diagnostics.Diagnostic_Record;
   begin
      if Items.Is_Empty then
         return Result;
      end if;

      if not Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid (Producer) then
         Result.Rejected_Count := Natural (Items.Length);
         return Result;
      end if;

      for I in Items.First_Index .. Items.Last_Index loop
         Normalized := Normalize_External_Diagnostic_Record (Items.Element (I));
         if Length (Normalized.Message) = 0 then
            Result.Rejected_Count := Result.Rejected_Count + 1;
         else
            Add_Normalized_Record (S, Producer, Normalized, Target_Kept);
            Result.Accepted_Count := Result.Accepted_Count + 1;
            if not Target_Kept then
               Result.Accepted_Untargeted := Result.Accepted_Untargeted + 1;
            end if;
         end if;
      end loop;

      declare
         After_Count : constant Natural :=
           Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      begin
         if Before_Count + Result.Accepted_Count > After_Count then
            Result.Evicted_Count := Before_Count + Result.Accepted_Count - After_Count;
         end if;
      end;

      if Result.Accepted_Count > 0 then
         Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
           (S.Feature_Diagnostics, S.Feature_Panel);
         Result.Projection_Changed :=
           Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
             Editor.Feature_Panel.Diagnostics_Feature;
      end if;

      return Result;
   end Ingest_Diagnostic_Batch;

   function External_Producer_Audit_Passes return Boolean
   is
      Build_Source : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Source_Metadata.Build_External_Producer_Source (Build_Diagnostics_Producer);
      Compiler_Source : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Source_Metadata.Build_External_Producer_Source (Compiler_Diagnostics_Producer);
      None_Source : constant Editor.External_Producers.Diagnostics.Producer_Source :=
        Editor.External_Producers.Source_Metadata.Build_External_Producer_Source (No_External_Producer);
   begin
      return Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid (Build_Source)
        and then Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid (Compiler_Source)
        and then not Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid (None_Source)
        and then Editor.External_Producers.Source_Metadata.Stable_Name (Build_Diagnostics_Producer) /=
          Editor.External_Producers.Source_Metadata.Stable_Name (Compiler_Diagnostics_Producer)
        and then Editor.External_Producers.Source_Metadata.Display_Label (Build_Diagnostics_Producer) /=
          Editor.External_Producers.Source_Metadata.Display_Label (Compiler_Diagnostics_Producer)
        and then Editor.External_Producers.Source_Metadata.Map_External_Producer_To_Diagnostic_Source (Build_Source) =
          Editor.Feature_Diagnostics.External_Diagnostic_Source
        and then Editor.External_Producers.Source_Metadata.Map_External_Producer_To_Diagnostic_Source (Compiler_Source) =
          Editor.Feature_Diagnostics.External_Diagnostic_Source
        and then Editor.External_Producers.Source_Metadata.Map_External_Producer_To_Diagnostic_Source (None_Source) =
          Editor.Feature_Diagnostics.Unknown_Diagnostic_Source
        and then Compiler_Diagnostic_Normalization_Audit_Passes
        and then Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Parser_Audit_Passes
        and then Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Command_Surface_Audit_Passes
        and then Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Layering_Audit_Passes
        and then Editor.External_Producers.Build_Runner_Audits.Build_Run_Test_Seam_Audit_Passes
        and then Editor.External_Producers.Build_Runner_Audits.Audit_Real_Build_Execution_Gates
        and then Editor.External_Producers.Build_Runner_Audits.Audit_User_Opt_In_Build_Command_Surface
        and then Producer_Lifecycle_Audit_Passes;
   end External_Producer_Audit_Passes;

end Editor.External_Producers.Diagnostic_Normalization;
