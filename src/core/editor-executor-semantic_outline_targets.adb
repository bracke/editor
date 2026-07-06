with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Model;
with Editor.Feature_Panel;
with Editor.Outline;

package body Editor.Executor.Semantic_Outline_Targets is

   use type Editor.Ada_Language_Model.Symbol_Kind;
   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Outline.Outline_Freshness;
   use type Editor.Outline.Outline_Item_Kind;

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
      Label : constant String :=
        Editor.Outline.Item_Label (S.Outline, Outline_Row);
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
      Label : constant String :=
        Editor.Outline.Item_Label (S.Outline, Outline_Row);
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
      Label : constant String :=
        Editor.Outline.Item_Label (S.Outline, Outline_Row);
   begin
      return Strip_Prefix (Label, "separate body ") /= Label;
   end Outline_Row_Is_Separate_Body;

   function Current_File_Has_Indexed_Separate_Body
     (S    : Editor.State.State_Type;
      Name : String) return Boolean
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
      Detail : constant String :=
        Editor.Outline.Item_Detail (S.Outline, Outline_Row);
      First_Paren : Natural := 0;
      Return_Pos  : Natural := 0;
   begin
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

   function Active_Outline_Source_Is_Current
     (S : Editor.State.State_Type) return Boolean
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Freshness : Editor.Outline.Outline_Freshness;
   begin
      if not Current_File.Has_Path
        or else S.Active_Buffer_Token = 0
      then
         return True;
      end if;

      Freshness := Editor.Outline.Freshness_For_Active_Buffer
        (S.Outline,
         S.Active_Buffer_Token,
         Editor.State.Current_Buffer_Revision (S));
      return Freshness /= Editor.Outline.Outline_Stale;
   end Active_Outline_Source_Is_Current;

   function Find_Indexed_Outline_Target
     (S             : Editor.State.State_Type;
      Id            : Editor.Commands.Command_Id;
      Service       : in out Editor.Ada_Language_Service.Service_State;
      Track_Request : Boolean := False) return Outline_Indexed_Target
   is
      Panel_Row : Natural := 0;
      Outline_Row : Natural := 0;
      Name : Unbounded_String := Null_Unbounded_String;
      Row_Kind : Editor.Outline.Outline_Item_Kind :=
        Editor.Outline.Outline_Unknown;
      Row_Is_Body : Boolean := False;
      Row_Profile : Unbounded_String := Null_Unbounded_String;
      Wanted : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
   begin
      if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
        or else not Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
      then
         return (others => <>);
      elsif not Active_Outline_Source_Is_Current (S) then
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
      Row_Is_Body := Outline_Row_Is_Body (S, Positive (Outline_Row));
      Row_Profile := To_Unbounded_String
        (Outline_Row_Profile (S, Positive (Outline_Row)));

      if Id = Editor.Commands.Command_Goto_Body then
         if Row_Kind = Editor.Outline.Outline_Package then
            Wanted := Editor.Ada_Language_Model.Symbol_Package_Body;
         elsif Row_Kind = Editor.Outline.Outline_Procedure
           and then not Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Procedure;
         elsif Row_Kind = Editor.Outline.Outline_Function
           and then not Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Function;
         else
            return (others => <>);
         end if;
      elsif Id = Editor.Commands.Command_Goto_Spec then
         if Outline_Row_Is_Separate_Body (S, Positive (Outline_Row))
           or else Current_File_Has_Indexed_Separate_Body
             (S, To_String (Name))
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Separate_Body;
         elsif Row_Kind = Editor.Outline.Outline_Package_Body then
            Wanted := Editor.Ada_Language_Model.Symbol_Package;
         elsif Row_Kind = Editor.Outline.Outline_Procedure
           and then Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Procedure;
         elsif Row_Kind = Editor.Outline.Outline_Function
           and then Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Function;
         else
            return (others => <>);
         end if;
      else
         return (others => <>);
      end if;

      if Track_Request then
         declare
            Req : constant Editor.Ada_Language_Service.Semantic_Request_Id :=
              Editor.Ada_Language_Service.Begin_Semantic_Request
                (Service,
                 (if Id = Editor.Commands.Command_Goto_Body
                  then Editor.Ada_Language_Service.Semantic_Request_Goto_Body
                  else Editor.Ada_Language_Service.Semantic_Request_Goto_Spec),
                 Editor.Ada_Language_Service.Semantic_Request_Query_Key
                   ((if Id = Editor.Commands.Command_Goto_Body
                     then Editor.Ada_Language_Service.Semantic_Request_Goto_Body
                     else Editor.Ada_Language_Service.Semantic_Request_Goto_Spec),
                    To_String (Name),
                    To_String (Row_Profile),
                    Detail => Editor.Ada_Language_Model.Symbol_Kind'Image
                      (Wanted)));
            Target_Set :
              constant Editor.Ada_Language_Service.Language_Target_Set :=
              (if Id = Editor.Commands.Command_Goto_Body then
                 Editor.Ada_Language_Service.Request_Goto_Body
                   (Service, Req, To_String (Name), Wanted,
                    To_String (Row_Profile))
               else
                 Editor.Ada_Language_Service.Request_Goto_Spec
                   (Service, Req, To_String (Name), Wanted,
                    To_String (Row_Profile)));
         begin
            if Target_Set.Status =
              Editor.Ada_Language_Service.Service_Success
              and then Natural (Target_Set.Targets.Length) = 1
            then
               declare
                  Target :
                    constant Editor.Ada_Language_Service.Language_Target :=
                    Target_Set.Targets (Target_Set.Targets.First_Index);
               begin
                  return
                    (Available => True,
                     Path      => Target.Target.Path,
                     Key       => Target.Key,
                     Line      => Target.Target.Line,
                     Column    => Target.Target.Column);
               end;
            end if;
         end;

         return (others => <>);
      end if;

      if Row_Kind = Editor.Outline.Outline_Package
        or else Row_Kind = Editor.Outline.Outline_Package_Body
      then
         declare
            Unit_Target :
              constant Editor.Ada_Project_Index.Unique_Target_Result :=
              Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
                (S.Language_Index,
                 To_String (Name),
                 (if Id = Editor.Commands.Command_Goto_Body then
                    Editor.Ada_Project_Index.Unit_Package_Body
                  else
                    Editor.Ada_Project_Index.Unit_Package_Spec));
         begin
            if Unit_Target.Available then
               return
                 (Available => True,
                  Path      => Unit_Target.Target.Path,
                  Key       => Unit_Target.Target.Key,
                  Line      => Unit_Target.Target.Symbol.Source_Span.Start_Line,
                  Column    => Unit_Target.Target.Symbol.Source_Span.Start_Column);
            elsif Unit_Target.Ambiguous or else Unit_Target.Overflow then
               return (others => <>);
            end if;
         end;
      end if;

      declare
         Target_Set :
           constant Editor.Ada_Language_Service.Language_Target_Set :=
           (if Id = Editor.Commands.Command_Goto_Body then
              Editor.Ada_Language_Service.Goto_Body
                (Service, To_String (Name), Wanted, To_String (Row_Profile))
            else
              Editor.Ada_Language_Service.Goto_Spec
                (Service, To_String (Name), Wanted, To_String (Row_Profile)));
      begin
         if Target_Set.Status = Editor.Ada_Language_Service.Service_Success
           and then Natural (Target_Set.Targets.Length) = 1
         then
            declare
               Target : constant Editor.Ada_Language_Service.Language_Target :=
                 Target_Set.Targets (Target_Set.Targets.First_Index);
            begin
               return
                 (Available => True,
                  Path      => Target.Target.Path,
                  Key       => Target.Key,
                  Line      => Target.Target.Line,
                  Column    => Target.Target.Column);
            end;
         end if;
      end;

      return (others => <>);
   end Find_Indexed_Outline_Target;

end Editor.Executor.Semantic_Outline_Targets;
