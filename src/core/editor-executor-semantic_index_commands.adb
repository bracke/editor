with Ada.Characters.Handling;
with Ada.Strings.Unbounded;

with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Live_Semantic_Diagnostics;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Executor;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Files;
with Editor.Project;
with Editor.State;
with Editor.Syntax_Semantics;

package body Editor.Executor.Semantic_Index_Commands is

   use Ada.Strings.Unbounded;
   use type Editor.Files.File_Open_Status;
   use type Editor.Project.Project_File_Refresh_Status;

   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural
      renames Editor.Executor.Active_Feature_Buffer_Token;

   function Ends_With
     (Text   : String;
      Suffix : String) return Boolean
   is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Is_Ada_Source_Path
     (Path : String) return Boolean
   is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Path);
   begin
      return Ends_With (Lower, ".adb") or else Ends_With (Lower, ".ads");
   end Is_Ada_Source_Path;

   function To_Feature_Severity
     (Severity : Editor.Ada_Language_Service.Semantic_Diagnostic_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Language_Service.Semantic_Error =>
            return Editor.Feature_Diagnostics.Diagnostic_Error;
         when Editor.Ada_Language_Service.Semantic_Warning =>
            return Editor.Feature_Diagnostics.Diagnostic_Warning;
         when Editor.Ada_Language_Service.Semantic_Info =>
            return Editor.Feature_Diagnostics.Diagnostic_Info;
         when Editor.Ada_Language_Service.Semantic_Hint =>
            return Editor.Feature_Diagnostics.Diagnostic_Note;
      end case;
   end To_Feature_Severity;

   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural)
   is
      Removed : Natural;
      Added   : Natural := 0;
   begin
      Removed := Editor.Feature_Diagnostics.Clear_Diagnostics_By_Source_And_Label
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Path);

      for I in 1 ..
        Editor.Ada_Language_Service.Semantic_Diagnostic_Count_For_Path
          (S.Language_Service, Path)
      loop
         declare
            Diagnostic : constant Editor.Ada_Language_Service.Semantic_Diagnostic :=
              Editor.Ada_Language_Service.Semantic_Diagnostic_At_For_Path
                (S.Language_Service, Path, I);
         begin
            if Diagnostic.Has_Command_Descriptor then
               Editor.Feature_Diagnostics.Add_Diagnostic_Command_Descriptor
                 (S.Feature_Diagnostics,
                  Diagnostic.Command_Descriptor,
                  Source_Label  => Path,
                  Target_Buffer => Buffer_Token);
            else
               Editor.Feature_Diagnostics.Add_Diagnostic
                 (S.Feature_Diagnostics,
                  Severity      => To_Feature_Severity (Diagnostic.Severity),
                  Message       => To_String (Diagnostic.Message),
                  Source_Label  => Path,
                  Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
                  Has_Target    => Diagnostic.Has_Location and then Buffer_Token /= 0,
                  Target_Buffer => Buffer_Token,
                  Target_Line   => (if Diagnostic.Has_Location then Diagnostic.Line else 0),
                  Target_Column => (if Diagnostic.Has_Location then Diagnostic.Column else 0));
            end if;
            Added := Added + 1;
         end;
      end loop;

      if Removed > 0 or else Added > 0 then
         Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
           (S.Feature_Diagnostics, S.Feature_Panel);
      end if;
   end Publish_Service_Diagnostics_To_Feature;

   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural)
   is
      Active_Path : constant String :=
        (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
      Active_Text : constant String := Editor.State.Current_Text (S);
      Active_Buffer_Token : constant Natural := Active_Feature_Buffer_Token (S);

      procedure Index_Text
        (Path                 : String;
         Text                 : String;
         Buffer_Token         : Natural;
         Buffer_Revision      : Natural;
         Lifecycle_Generation : Natural;
         Update_Semantics     : Boolean)
      is
         Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
           Editor.Ada_Declaration_Parser.Parse (Text, Path);
      begin
         Editor.Ada_Project_Index.Put_Analysis
           (S.Language_Index,
            Path,
            Buffer_Token,
            Buffer_Revision,
            Lifecycle_Generation,
            Analysis);

         if Update_Semantics then
            Editor.Syntax_Semantics.Clear (S.Syntax_Symbols);
            S.Syntax_Analysis := Analysis;
            Editor.Syntax_Semantics.Build_Map_From_Analysis
              (S.Syntax_Symbols, Analysis);
            S.Syntax_Symbols_Revision := Editor.State.Current_Buffer_Revision (S);
            S.Syntax_Symbols_Buffer_Token := Active_Buffer_Token;
            Editor.Ada_Live_Semantic_Diagnostics.Publish
              (S.Language_Service,
               Path,
               Text,
               Buffer_Token,
               Buffer_Revision,
               Lifecycle_Generation,
               Analysis);
            Publish_Service_Diagnostics_To_Feature (S, Path, Buffer_Token);
         end if;
      end Index_Text;

      procedure Index_Open_Buffer_Overlays is
         Registry : constant Editor.Buffers.Buffer_Registry :=
           Editor.Buffers.Global_Registry_For_UI;
      begin
         --  Project refresh must prefer open-buffer snapshots over disk reads.
         for J in 1 .. Editor.Buffers.Count (Registry) loop
            exit when Editor.Ada_Project_Index.File_Count (S.Language_Index) >=
              Editor.Ada_Project_Index.Max_Index_Files;

            declare
               Summary : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Summary_At (Registry, J);
               Path : constant String := To_String (Summary.Path);
            begin
               if Summary.Has_Path
                 and then Path'Length > 0
                 and then Is_Ada_Source_Path (Path)
                 and then Natural (Summary.Id) /= Active_Buffer_Token
               then
                  declare
                     Buffer_State : constant Editor.State.State_Type :=
                       Editor.Buffers.Buffer (Registry, Summary.Id);
                  begin
                     Editor.Ada_Project_Index.Invalidate_Path
                       (S.Language_Index, Path);
                     Index_Text
                       (Path,
                        Editor.State.Current_Text (Buffer_State),
                        Natural (Summary.Id),
                        Editor.State.Current_Buffer_Revision (Buffer_State),
                        Editor.State.Current_Lifecycle_Generation (Buffer_State),
                        False);
                  end;
               end if;
            end;
         end loop;
      end Index_Open_Buffer_Overlays;
   begin
      Indexed_File_Count := 0;
      Indexed_Symbols := 0;
      Skipped_File_Count := 0;
      Read_Error_Count := 0;

      Editor.Ada_Project_Index.Clear (S.Language_Index);

      if Editor.Project.Has_Project (S.Project) then
         declare
            Refresh_Result : Editor.Project.Project_File_Refresh_Result;
         begin
            Editor.Project.Refresh_Known_Files (S.Project, Refresh_Result);
            if Refresh_Result.Status /= Editor.Project.Project_File_Refresh_Ok then
               Read_Error_Count := Read_Error_Count + 1;
            end if;
         end;

         if Active_Path'Length > 0
           and then Is_Ada_Source_Path (Active_Path)
           and then Editor.Ada_Project_Index.File_Count (S.Language_Index) <
             Editor.Ada_Project_Index.Max_Index_Files
         then
            Index_Text
              (Active_Path,
               Active_Text,
               Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Build_Semantics);
         end if;

         Index_Open_Buffer_Overlays;

         for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
            exit when Editor.Ada_Project_Index.File_Count (S.Language_Index) >=
              Editor.Ada_Project_Index.Max_Index_Files;

            declare
               Known : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (S.Project, I);
               Path : constant String := To_String (Known.Absolute_Path);
            begin
               if Path'Length = 0 or else not Is_Ada_Source_Path (Path) then
                  Skipped_File_Count := Skipped_File_Count + 1;
               elsif Editor.Ada_Project_Index.Contains_Path
                 (S.Language_Index, Path)
               then
                  null;
               else
                  declare
                     Opened : constant Editor.Files.File_Open_Result :=
                       Editor.Files.Open_File (Path);
                  begin
                     if Opened.Status = Editor.Files.File_Open_Ok then
                        Index_Text
                          (To_String (Opened.Path),
                           To_String (Opened.Contents),
                           0,
                           0,
                           0,
                           False);
                     else
                        Read_Error_Count := Read_Error_Count + 1;
                     end if;
                  end;
               end if;
            end;
         end loop;
      else
         declare
            Label : constant String :=
              (if Active_Path'Length > 0 then Active_Path
               else To_String (S.File_Info.Display_Name));
         begin
            if Label'Length > 0 and then Is_Ada_Source_Path (Label) then
               Index_Text
                 (Label,
                  Active_Text,
                  Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Build_Semantics);
            else
               Skipped_File_Count := Skipped_File_Count + 1;
            end if;
         end;
      end if;

      Indexed_File_Count := Editor.Ada_Project_Index.File_Count (S.Language_Index);
      Indexed_Symbols := Editor.Ada_Project_Index.Symbol_Count (S.Language_Index);
      Editor.Ada_Language_Service.Put_Index
        (S.Language_Service, S.Language_Index);
      if Build_Semantics then
         if Active_Path'Length > 0 and then Is_Ada_Source_Path (Active_Path) then
            Editor.Ada_Live_Semantic_Diagnostics.Publish
              (S.Language_Service,
               Active_Path,
               Active_Text,
               Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               S.Syntax_Analysis);
         end if;

         Editor.Ada_Live_Semantic_Diagnostics.Publish_Cross_Unit
           (S.Language_Service, S.Language_Index);

         for I in 1 .. Editor.Ada_Project_Index.File_Count (S.Language_Index) loop
            declare
               Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
                 Editor.Ada_Project_Index.File_Key_At (S.Language_Index, I);
            begin
               Publish_Service_Diagnostics_To_Feature
                 (S, To_String (Key.Path), Key.Buffer_Token);
            end;
         end loop;
      end if;
   end Refresh_Project_Language_Index;

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type)
   is
      Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
        S.Language_Index;
      Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
        S.Language_Service;
   begin
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.Language_Index := Saved_Index;
      S.Language_Service := Saved_Service;
   end Load_Global_Active_Preserving_Language_Index;

   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type)
   is
      Saved_Project : constant Editor.Project.Project_State := S.Project;
      Indexed_Files : Natural := 0;
      Indexed_Symbols : Natural := 0;
      Skipped_Files : Natural := 0;
      Read_Errors : Natural := 0;
   begin
      Refresh_Project_Language_Index
        (S,
         Build_Semantics    => True,
         Indexed_File_Count => Indexed_Files,
         Indexed_Symbols    => Indexed_Symbols,
         Skipped_File_Count => Skipped_Files,
         Read_Error_Count   => Read_Errors);

      if Indexed_Files = Natural'Last
        and then Indexed_Symbols = Natural'Last
        and then Skipped_Files = Natural'Last
        and then Read_Errors = Natural'Last
      then
         null;
      end if;

      S.Project := Saved_Project;
   end Rebuild_Language_Index_After_File_Lifecycle;

   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type)
   is
      Removed : Natural := 0;
   begin
      for I in 1 ..
        Editor.Ada_Language_Service.Semantic_Diagnostic_Count (S.Language_Service)
      loop
         declare
            Diagnostic : constant Editor.Ada_Language_Service.Semantic_Diagnostic :=
              Editor.Ada_Language_Service.Semantic_Diagnostic_At
                (S.Language_Service, I);
            Path : constant String := To_String (Diagnostic.Path);
         begin
            if Path'Length > 0 then
               Removed := Removed +
                 Editor.Feature_Diagnostics.Clear_Diagnostics_By_Source_And_Label
                   (S.Feature_Diagnostics,
                    Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
                    Path);
            end if;
         end;
      end loop;

      if Removed > 0 then
         Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
           (S.Feature_Diagnostics, S.Feature_Panel);
      end if;
   end Clear_Service_Semantic_Diagnostics_From_Feature;

end Editor.Executor.Semantic_Index_Commands;
