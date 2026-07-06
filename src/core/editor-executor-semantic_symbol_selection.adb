with Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Project_Index;
with Editor.Feature_Panel;
with Editor.Outline;

package body Editor.Executor.Semantic_Symbol_Selection is

   use type Editor.Ada_Language_Model.Symbol_Kind;
   use type Ada.Containers.Count_Type;
   use type Editor.Outline.Outline_Item_Kind;

   function To_Navigation_Symbol
     (Symbol : Selected_Semantic_Symbol)
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

   function Selected_Outline_Symbol
     (S : Editor.State.State_Type) return Selected_Semantic_Symbol
   is
      Panel_Row   : Natural := 0;
      Outline_Row : Natural := 0;
      Row_Kind    : Editor.Outline.Outline_Item_Kind :=
        Editor.Outline.Outline_Unknown;
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
     (S : Editor.State.State_Type) return Selected_Semantic_Symbol
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
     (S : Editor.State.State_Type) return Selected_Semantic_Symbol
   is
      Outline_Symbol : constant Selected_Semantic_Symbol :=
        Selected_Outline_Symbol (S);
   begin
      if Outline_Symbol.Available then
         return Outline_Symbol;
      end if;

      return Caret_Semantic_Symbol (S);
   end Current_Semantic_Symbol;

   function Current_Completion_Symbol
     (S : Editor.State.State_Type) return Selected_Semantic_Symbol
   is
      Caret_Symbol : constant Selected_Semantic_Symbol :=
        Caret_Semantic_Symbol (S);
   begin
      if Caret_Symbol.Available then
         return Caret_Symbol;
      end if;

      return Selected_Outline_Symbol (S);
   end Current_Completion_Symbol;

   function Current_Semantic_Symbol_Name
     (S : Editor.State.State_Type) return String
   is
      Symbol : constant Selected_Semantic_Symbol :=
        Current_Semantic_Symbol (S);
   begin
      if Symbol.Available then
         return To_String (Symbol.Name);
      end if;

      return "";
   end Current_Semantic_Symbol_Name;

end Editor.Executor.Semantic_Symbol_Selection;
