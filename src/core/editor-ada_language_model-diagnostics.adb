with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Language_Model.Hashing; use Editor.Ada_Language_Model.Hashing;
with Editor.Ada_Language_Model.Symbols; use Editor.Ada_Language_Model.Symbols;
with Editor.Ada_Language_Model.Generic_Metadata; use Editor.Ada_Language_Model.Generic_Metadata;
with Editor.Ada_Language_Model.Representation_Metadata; use Editor.Ada_Language_Model.Representation_Metadata;
with Editor.Ada_Language_Model.Diagnostics; use Editor.Ada_Language_Model.Diagnostics;
with Editor.Ada_Language_Model.Visibility; use Editor.Ada_Language_Model.Visibility;
with Editor.Ada_Language_Model.Syntax_Attachment; use Editor.Ada_Language_Model.Syntax_Attachment;

package body Editor.Ada_Language_Model.Diagnostics is

   pragma Suppress (Overflow_Check);

   procedure Add_Legality_Diagnostic
     (Analysis       : in out Analysis_Result;
      Kind           : Legality_Diagnostic_Kind;
      Message        : String;
      Severity       : Legality_Diagnostic_Severity := Legality_Error;
      Primary_Symbol : Symbol_Id := No_Symbol;
      Related_Symbol : Symbol_Id := No_Symbol;
      Source_Span          : Source_Range := (others => 1))
   is
      Info : Legality_Diagnostic_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Message'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Legality_Diagnostics.Length) >= Max_Legality_Diagnostics then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579456) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Kind := Kind;
      Info.Severity := Severity;
      Info.Primary_Symbol := Primary_Symbol;
      Info.Related_Symbol := Related_Symbol;
      if Primary_Symbol /= No_Symbol
        and then Natural (Primary_Symbol) <= Natural (Analysis.Symbols.Length)
      then
         Info.Target_Name :=
           Analysis.Symbols.Element (Positive (Primary_Symbol)).Name;
      end if;
      Info.Message := To_Unbounded_String (Message);
      Info.Source_Span := Source_Span;

      H := (H * 131 + Natural (Legality_Diagnostic_Kind'Pos (Kind)) + 1)
        mod 2_147_483_647;
      H := (H * 131 + Natural (Legality_Diagnostic_Severity'Pos (Severity)) + 3)
        mod 2_147_483_647;
      H := (H * 131 + Natural (Primary_Symbol) + Natural (Related_Symbol) + 5)
        mod 2_147_483_647;
      H := Hash_String (H, Message);
      Info.Fingerprint := H;

      Analysis.Legality_Diagnostics.Append (Info);
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579457) mod 2_147_483_647;
   end Add_Legality_Diagnostic;


   function Legality_Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Legality_Diagnostics loop
         if Info.Severity = Severity then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legality_Diagnostic_Count;


   function Legality_Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Legality_Diagnostic_Info
   is
   begin
      if Natural (Analysis.Legality_Diagnostics.Length) > 0
        and then Index <= Positive (Analysis.Legality_Diagnostics.Length)
      then
         return Analysis.Legality_Diagnostics.Element (Index);
      end if;

      return (Kind => Legality_Duplicate_Declaration,
              Severity => Legality_Error,
              Primary_Symbol => No_Symbol,
              Related_Symbol => No_Symbol,
              Target_Name => Null_Unbounded_String,
              Message => Null_Unbounded_String,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Legality_Diagnostic_At;


   function Has_Legality_Diagnostics
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Boolean
   is
   begin
      return Legality_Diagnostic_Count (Analysis, Severity) > 0;
   end Has_Legality_Diagnostics;


   function Diagnostic_Count
     (Analysis : Analysis_Result;
      Severity : Legality_Diagnostic_Severity := Legality_Error) return Natural is
   begin
      return Legality_Diagnostic_Count (Analysis, Severity);
   end Diagnostic_Count;


   function Diagnostic_At
     (Analysis : Analysis_Result;
      Index    : Positive) return Diagnostic_Info is
   begin
      return Legality_Diagnostic_At (Analysis, Index);
   end Diagnostic_At;



end Editor.Ada_Language_Model.Diagnostics;
