with Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Semantic_Completion_Commands;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Semantic_Navigation_Commands;
with Editor.Executor.Semantic_Rename_Commands;
with Editor.Executor.Semantic_Service_Commands;
with Editor.Feature_Panel;
with Editor.Outline;
with Editor.Render_Cache;
with Editor.State;
with Editor.UTF8;

package body Editor.Executor.Semantic_Commands is

   use Ada.Strings.Unbounded;
   use Editor.Commands;
   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Language_Model.Symbol_Kind;
   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.State.Semantic_Popup_Kind;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Is_Ada_Source_Path
     (Path : String) return Boolean
      renames Editor.Executor.Semantic_Index_Commands.Is_Ada_Source_Path;

   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural)
      renames Editor.Executor.Semantic_Index_Commands
        .Publish_Service_Diagnostics_To_Feature;

   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural)
      renames Editor.Executor.Semantic_Index_Commands
        .Refresh_Project_Language_Index;

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Index_Commands
        .Load_Global_Active_Preserving_Language_Index;

   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Index_Commands
        .Rebuild_Language_Index_After_File_Lifecycle;

   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Index_Commands
        .Clear_Service_Semantic_Diagnostics_From_Feature;

   type Selected_Outline_Semantic_Symbol is record
      Available : Boolean := False;
      Name      : Unbounded_String := Null_Unbounded_String;
      Kind      : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Profile   : Unbounded_String := Null_Unbounded_String;
   end record;

   function To_Navigation_Symbol
     (Symbol : Selected_Outline_Semantic_Symbol)
      return Editor.Executor.Semantic_Navigation_Commands.Semantic_Symbol
   is
   begin
      return
        (Available => Symbol.Available,
         Name      => Symbol.Name,
         Kind      => Symbol.Kind,
         Profile   => Symbol.Profile);
   end To_Navigation_Symbol;

   function Strip_Trailing_Word
     (Text : String;
      Word : String) return String
   is
   begin
      if Text'Length > Word'Length
        and then Text (Text'Last - Word'Length + 1 .. Text'Last) = Word
      then
         declare
            Last : Natural := Text'Last - Word'Length;
         begin
            while Last >= Text'First
              and then (Text (Last) = ' ' or else Text (Last) = ASCII.HT)
            loop
               exit when Last = Text'First;
               Last := Last - 1;
            end loop;
            if Last >= Text'First then
               return Text (Text'First .. Last);
            end if;
         end;
      end if;
      return Text;
   end Strip_Trailing_Word;

   function Strip_Prefix
     (Text   : String;
      Prefix : String) return String
   is
   begin
      if Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix
      then
         if Text'First + Prefix'Length <= Text'Last then
            return Text (Text'First + Prefix'Length .. Text'Last);
         else
            return "";
         end if;
      end if;
      return Text;
   end Strip_Prefix;

   function Outline_Row_Base_Name
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return String
   is
      Label : constant String := Editor.Outline.Item_Label (S.Outline, Outline_Row);
      Name  : Unbounded_String := To_Unbounded_String (Label);
   begin
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic package "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "package body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "package "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic subprogram body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic subprogram "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic procedure body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic procedure "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "procedure body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "procedure "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic function body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic function "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "function body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "function "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "record extension type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "private extension type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "null extension type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "variant record type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "record type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "task body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "task type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "task "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "protected body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "protected type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "protected "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "entry "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "subtype "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "field "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "discriminant "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "literal "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "object "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "constant "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "exception "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal package "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal procedure "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal function "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal object "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "separate body "));
      Name := To_Unbounded_String (Strip_Trailing_Word (To_String (Name), " renames"));
      Name := To_Unbounded_String (Strip_Trailing_Word (To_String (Name), " instantiation"));
      return To_String (Name);
   end Outline_Row_Base_Name;

   function Outline_Row_Is_Body
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return Boolean
   is
      Label : constant String := Editor.Outline.Item_Label (S.Outline, Outline_Row);
   begin
      return Label'Length >= 13
        and then
          (Strip_Prefix (Label, "package body ") /= Label
           or else Strip_Prefix (Label, "procedure body ") /= Label
           or else Strip_Prefix (Label, "function body ") /= Label
           or else Strip_Prefix (Label, "generic procedure body ") /= Label
           or else Strip_Prefix (Label, "generic function body ") /= Label
           or else Strip_Prefix (Label, "generic subprogram body ") /= Label
           or else Strip_Prefix (Label, "separate body ") /= Label);
   end Outline_Row_Is_Body;

   function Outline_Row_Is_Separate_Body
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return Boolean
   is
      Label : constant String := Editor.Outline.Item_Label (S.Outline, Outline_Row);
   begin
      return Strip_Prefix (Label, "separate body ") /= Label;
   end Outline_Row_Is_Separate_Body;

   function Current_File_Has_Indexed_Separate_Body
     (S           : Editor.State.State_Type;
      Name        : String) return Boolean
   is
      Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve (S.Language_Index, Name);
      Path : constant String :=
        (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
   begin
      if Path'Length = 0 or else Matches.Overflow then
         return False;
      end if;

      for Match of Matches.Matches loop
         if To_String (Match.Path) = Path
           and then Match.Symbol.Kind =
             Editor.Ada_Language_Model.Symbol_Separate_Body
         then
            return True;
         end if;
      end loop;

      return False;
   end Current_File_Has_Indexed_Separate_Body;

   function Outline_Row_Profile
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return String
   is
      Detail : constant String := Editor.Outline.Item_Detail (S.Outline, Outline_Row);
      First_Paren : Natural := 0;
      Return_Pos  : Natural := 0;
   begin
      --  Outline details generated from Ada_Language_Model place retained
      --  callable profile summaries after the stable line/form prefix, for
      --  example "line 12 (X : Integer)" or
      --  "line 12 body return Boolean".  Keep this parser deliberately
      --  conservative: it extracts only the two profile shapes currently
      --  emitted by Symbol_Detail and otherwise leaves navigation name/kind
      --  matching unchanged.
      for I in Detail'Range loop
         if Detail (I) = '(' then
            First_Paren := I;
            exit;
         end if;
      end loop;

      if First_Paren /= 0 then
         return Ada.Strings.Fixed.Trim
           (Detail (First_Paren .. Detail'Last), Ada.Strings.Both);
      end if;

      if Detail'Length >= 8 then
         for I in Detail'First .. Detail'Last - 7 loop
            if Detail (I .. I + 7) = " return " then
               Return_Pos := I + 1;
            end if;
         end loop;
      end if;

      if Return_Pos /= 0 then
         return Ada.Strings.Fixed.Trim
           (Detail (Return_Pos .. Detail'Last), Ada.Strings.Both);
      end if;

      return "";
   end Outline_Row_Profile;

   function Selected_Outline_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Panel_Row   : Natural := 0;
      Outline_Row : Natural := 0;
      Row_Kind    : Editor.Outline.Outline_Item_Kind := Editor.Outline.Outline_Unknown;
      Name        : Unbounded_String := Null_Unbounded_String;
      Kind        : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
   begin
      if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
        or else not Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
      then
         return (others => <>);
      end if;

      Panel_Row := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Outline_Row := Editor.Outline.Map_Panel_Row_To_Outline_Row
        (S.Outline, S.Feature_Panel, Panel_Row);
      if Outline_Row = 0
        or else not Editor.Outline.Validate_Outline_Row_For_Selection
          (S.Outline, S.Feature_Panel, Panel_Row)
      then
         return (others => <>);
      end if;

      Name := To_Unbounded_String
        (Outline_Row_Base_Name (S, Positive (Outline_Row)));
      if Length (Name) = 0 then
         return (others => <>);
      end if;

      Row_Kind := Editor.Outline.Item_Kind (S.Outline, Positive (Outline_Row));
      case Row_Kind is
         when Editor.Outline.Outline_Package =>
            Kind := Editor.Ada_Language_Model.Symbol_Package;
         when Editor.Outline.Outline_Package_Body =>
            Kind := Editor.Ada_Language_Model.Symbol_Package_Body;
         when Editor.Outline.Outline_Procedure =>
            Kind := Editor.Ada_Language_Model.Symbol_Procedure;
         when Editor.Outline.Outline_Function =>
            Kind := Editor.Ada_Language_Model.Symbol_Function;
         when Editor.Outline.Outline_Subprogram =>
            Kind := Editor.Ada_Language_Model.Symbol_Procedure;
         when Editor.Outline.Outline_Type =>
            Kind := Editor.Ada_Language_Model.Symbol_Type;
         when Editor.Outline.Outline_Task =>
            Kind := Editor.Ada_Language_Model.Symbol_Task;
         when Editor.Outline.Outline_Protected =>
            Kind := Editor.Ada_Language_Model.Symbol_Protected;
         when Editor.Outline.Outline_Field =>
            Kind := Editor.Ada_Language_Model.Symbol_Record_Component;
         when Editor.Outline.Outline_Discriminant =>
            Kind := Editor.Ada_Language_Model.Symbol_Discriminant;
         when Editor.Outline.Outline_Enum_Literal =>
            Kind := Editor.Ada_Language_Model.Symbol_Enumeration_Literal;
         when Editor.Outline.Outline_Exception =>
            Kind := Editor.Ada_Language_Model.Symbol_Exception;
         when Editor.Outline.Outline_Object =>
            Kind := Editor.Ada_Language_Model.Symbol_Object;
         when Editor.Outline.Outline_Generic_Formal =>
            Kind := Editor.Ada_Language_Model.Symbol_Generic_Formal_Type;
         when others =>
            Kind := Editor.Ada_Language_Model.Symbol_Unknown;
      end case;

      if Kind = Editor.Ada_Language_Model.Symbol_Unknown then
         return (others => <>);
      end if;

      return
        (Available => True,
         Name      => Name,
         Kind      => Kind,
         Profile   => To_Unbounded_String
           (Outline_Row_Profile (S, Positive (Outline_Row))));
   end Selected_Outline_Symbol;

   function Is_Ada_Identifier_Start (Ch : Character) return Boolean is
   begin
      return (Ch >= 'A' and then Ch <= 'Z')
        or else (Ch >= 'a' and then Ch <= 'z');
   end Is_Ada_Identifier_Start;

   function Is_Ada_Identifier_Part (Ch : Character) return Boolean is
   begin
      return Is_Ada_Identifier_Start (Ch)
        or else (Ch >= '0' and then Ch <= '9')
        or else Ch = '_';
   end Is_Ada_Identifier_Part;

   function Caret_Semantic_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Text       : constant String := Editor.State.Current_Text (S);
      Caret_Pos  : Natural := 0;
      Probe      : Natural;
      First_Char : Natural;
      Last_Char  : Natural;
   begin
      if Text'Length = 0 or else S.Carets.Length = 0 then
         return (others => <>);
      end if;

      Caret_Pos := Natural (S.Carets (S.Carets.First_Index).Pos);
      if Caret_Pos >= Text'Length then
         Probe := Text'Last;
      else
         Probe := Text'First + Caret_Pos;
      end if;

      if not Is_Ada_Identifier_Part (Text (Probe))
        and then Probe > Text'First
        and then Is_Ada_Identifier_Part (Text (Probe - 1))
      then
         Probe := Probe - 1;
      end if;

      if not Is_Ada_Identifier_Part (Text (Probe)) then
         return (others => <>);
      end if;

      First_Char := Probe;
      while First_Char > Text'First
        and then Is_Ada_Identifier_Part (Text (First_Char - 1))
      loop
         First_Char := First_Char - 1;
      end loop;

      Last_Char := Probe;
      while Last_Char < Text'Last
        and then Is_Ada_Identifier_Part (Text (Last_Char + 1))
      loop
         Last_Char := Last_Char + 1;
      end loop;

      if not Is_Ada_Identifier_Start (Text (First_Char)) then
         return (others => <>);
      end if;

      return
        (Available => True,
         Name      => To_Unbounded_String (Text (First_Char .. Last_Char)),
         Kind      => Editor.Ada_Language_Model.Symbol_Unknown,
         Profile   => Null_Unbounded_String);
   end Caret_Semantic_Symbol;

   function Current_Semantic_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Outline_Symbol : constant Selected_Outline_Semantic_Symbol :=
        Selected_Outline_Symbol (S);
   begin
      if Outline_Symbol.Available then
         return Outline_Symbol;
      end if;

      return Caret_Semantic_Symbol (S);
   end Current_Semantic_Symbol;

   function Current_Completion_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Caret_Symbol : constant Selected_Outline_Semantic_Symbol :=
        Caret_Semantic_Symbol (S);
   begin
      if Caret_Symbol.Available then
         return Caret_Symbol;
      end if;

      return Selected_Outline_Symbol (S);
   end Current_Completion_Symbol;

   function Current_Semantic_Symbol_Name
     (State : Editor.State.State_Type) return String
   is
      Symbol : constant Selected_Outline_Semantic_Symbol :=
        Current_Semantic_Symbol (State);
   begin
      if Symbol.Available then
         return To_String (Symbol.Name);
      end if;

      return "";
   end Current_Semantic_Symbol_Name;

   function Service_Status_Image
     (Status : Editor.Ada_Language_Service.Service_Status) return String
   is
   begin
      case Status is
         when Editor.Ada_Language_Service.Service_Success =>
            return "success";
         when Editor.Ada_Language_Service.Service_Unavailable =>
            return "unavailable";
         when Editor.Ada_Language_Service.Service_Ambiguous =>
            return "ambiguous";
         when Editor.Ada_Language_Service.Service_Overflow =>
            return "overflow";
         when Editor.Ada_Language_Service.Service_Stale =>
            return "stale";
      end case;
   end Service_Status_Image;

   function Current_Language_Service
     (S : Editor.State.State_Type)
      return Editor.Ada_Language_Service.Service_State
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count = Index_Status.File_Count
        and then Service_Status.Unit_Count = Index_Status.Unit_Count
        and then Service_Status.Symbol_Count = Index_Status.Symbol_Count
        and then Service_Status.Fingerprint = Index_Status.Fingerprint
        and then Service_Status.Overflowed = Index_Status.Overflowed
      then
         return S.Language_Service;
      end if;

      return Editor.Ada_Language_Service.From_Index (S.Language_Index);
   end Current_Language_Service;

   procedure Ensure_Current_Language_Service
     (S : in out Editor.State.State_Type)
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count /= Index_Status.File_Count
        or else Service_Status.Unit_Count /= Index_Status.Unit_Count
        or else Service_Status.Symbol_Count /= Index_Status.Symbol_Count
        or else Service_Status.Fingerprint /= Index_Status.Fingerprint
        or else Service_Status.Overflowed /= Index_Status.Overflowed
      then
         Editor.Ada_Language_Service.Put_Index
         (S.Language_Service, S.Language_Index);
      end if;
   end Ensure_Current_Language_Service;

   procedure Clear_Semantic_Popup
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Completion_Commands
        .Clear_Semantic_Popup;

   function Semantic_Completion_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean
      renames Editor.Executor.Semantic_Completion_Commands
        .Semantic_Completion_Popup_Is_Active;

   procedure Execute_Semantic_Completion_Select
     (S    : in out Editor.State.State_Type;
      Next : Boolean)
      renames Editor.Executor.Semantic_Completion_Commands
        .Execute_Semantic_Completion_Select;

   procedure Execute_Semantic_Completion_Accept
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Completion_Commands
        .Execute_Semantic_Completion_Accept;

   function Selected_Outline_Language_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      Symbol  : constant Selected_Outline_Semantic_Symbol :=
        (if Id = Editor.Commands.Command_Show_Completions
         then Current_Completion_Symbol (S)
         else Current_Semantic_Symbol (S));
      Service : Editor.Ada_Language_Service.Service_State :=
        Current_Language_Service (S);
      Name    : constant String := To_String (Symbol.Name);
   begin
      if not Symbol.Available then
         return Editor.Commands.Unavailable ("No semantic symbol at cursor or Outline selection.");
      end if;

      case Id is
         when Editor.Commands.Command_Find_References =>
            return Editor.Executor.Semantic_Service_Commands
              .Semantic_Service_Command_Availability (S, Id, Service, Name);

         when Editor.Commands.Command_Workspace_Symbols =>
            return Editor.Executor.Semantic_Service_Commands
              .Semantic_Service_Command_Availability (S, Id, Service, Name);

         when Editor.Commands.Command_Show_Hover =>
            return Editor.Executor.Semantic_Service_Commands
              .Semantic_Service_Command_Availability (S, Id, Service, Name);

         when Editor.Commands.Command_Show_Completions =>
            return Editor.Executor.Semantic_Service_Commands
              .Semantic_Service_Command_Availability (S, Id, Service, Name);

         when Editor.Commands.Command_Rename_Symbol_Preview =>
            return Editor.Executor.Semantic_Rename_Commands
              .Semantic_Rename_Command_Availability
                (S, Id, Service, Name);

         when Editor.Commands.Command_Rename_Symbol_Apply =>
            return Editor.Executor.Semantic_Rename_Commands
              .Semantic_Rename_Command_Availability
                (S, Id, Service, Name);

         when others =>
            return Editor.Commands.Unavailable ("Unsupported language command.");
      end case;
   end Selected_Outline_Language_Command_Availability;

   function Semantic_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Refresh_Outline_Project_Index
            | Editor.Commands.Command_Semantic_Refresh_Buffer
            | Editor.Commands.Command_Semantic_Refresh_Project_Index
            | Editor.Commands.Command_Language_Index_Clear
            | Editor.Commands.Command_Language_Index_Status =>
            return Editor.Executor.Semantic_Index_Commands
              .Semantic_Index_Command_Availability (S, Id);

         when Editor.Commands.Command_Goto_Declaration =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Semantic_Navigation_Command_Availability
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Semantic_Navigation_Command_Availability
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions
            | Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            return Selected_Outline_Language_Command_Availability (S, Id);

         when Editor.Commands.Command_Semantic_Completion_Select_Next
            | Editor.Commands.Command_Semantic_Completion_Select_Previous
            | Editor.Commands.Command_Semantic_Completion_Accept =>
            if Semantic_Completion_Popup_Is_Active (S) then
               return Editor.Commands.Available;
            end if;
            return Editor.Commands.Unavailable ("No completion menu is open.");

         when Editor.Commands.Command_Semantic_Popup_Dismiss =>
            if S.Semantic_Popup.Active then
               return Editor.Commands.Available;
            end if;
            return Editor.Commands.Unavailable ("No semantic popup is open.");

         when others =>
            return Editor.Commands.Unavailable
              ("Unsupported semantic command.");
      end case;
   end Semantic_Command_Availability;

   function Execute_Selected_Outline_Language_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Target_Name : String := "")
      return Editor.Command_Execution.Command_Execution_Result
   is
      Symbol  : constant Selected_Outline_Semantic_Symbol :=
        (if Id = Editor.Commands.Command_Show_Completions
         then Current_Completion_Symbol (S)
         else Current_Semantic_Symbol (S));
      Name    : constant String := To_String (Symbol.Name);
      Rename_To : constant String :=
        (if Target_Name'Length > 0 then Target_Name else Name & "_Renamed");
   begin
      Ensure_Current_Language_Service (S);
      if not Symbol.Available then
         Report_Info (S, "No semantic symbol at cursor or Outline selection.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.Unavailable (Id);
      end if;

      case Id is
         when Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions =>
            return Editor.Executor.Semantic_Service_Commands
              .Execute_Semantic_Service_Command (S, Id, Name);

         when Editor.Commands.Command_Rename_Symbol_Preview =>
            return Editor.Executor.Semantic_Rename_Commands
              .Execute_Semantic_Rename_Command (S, Id, Name, Rename_To);

         when Editor.Commands.Command_Rename_Symbol_Apply =>
            return Editor.Executor.Semantic_Rename_Commands
              .Execute_Semantic_Rename_Command (S, Id, Name, Rename_To);

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Selected_Outline_Language_Command;

   function Execute_Semantic_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result
   is
      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result is
      begin
         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;
   begin
      case Id is
         when Editor.Commands.Command_Refresh_Outline_Project_Index
            | Editor.Commands.Command_Semantic_Refresh_Buffer
            | Editor.Commands.Command_Semantic_Refresh_Project_Index
            | Editor.Commands.Command_Language_Index_Clear
            | Editor.Commands.Command_Language_Index_Status =>
            return Editor.Executor.Semantic_Index_Commands
              .Execute_Semantic_Index_Command (S, Id);

         when Editor.Commands.Command_Goto_Declaration =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Execute_Semantic_Navigation_Command
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            return Editor.Executor.Semantic_Navigation_Commands
              .Execute_Semantic_Navigation_Command
                (S, Id, To_Navigation_Symbol (Current_Semantic_Symbol (S)));

         when Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions =>
            return Execute_Selected_Outline_Language_Command (S, Id);

         when Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            return Execute_Selected_Outline_Language_Command
              (S, Id, To_String (Cmd.Text));

         when Editor.Commands.Command_Semantic_Completion_Select_Next =>
            Execute_Semantic_Completion_Select (S, Next => True);
            return Result_After_Command (Id);

         when Editor.Commands.Command_Semantic_Completion_Select_Previous =>
            Execute_Semantic_Completion_Select (S, Next => False);
            return Result_After_Command (Id);

         when Editor.Commands.Command_Semantic_Completion_Accept =>
            if not Semantic_Completion_Popup_Is_Active (S) then
               Report_Info (S, "No completion menu is open.");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;
            Execute_Semantic_Completion_Accept (S);
            return Result_After_Command (Id);

         when Editor.Commands.Command_Semantic_Popup_Dismiss =>
            if not S.Semantic_Popup.Active then
               Report_Info (S, "No semantic popup is open.");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;
            Clear_Semantic_Popup (S);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Semantic_Command;

end Editor.Executor.Semantic_Commands;
