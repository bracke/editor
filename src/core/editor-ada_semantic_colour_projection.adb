with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Semantic_Colour_Projection is

   use type Editor.Syntax.Token_Kind;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 1_000_000_007;
   end Mix;

   function Token_For_Severity
     (Severity : Semantic_Colour_Severity) return Editor.Syntax.Token_Kind
   is
   begin
      case Severity is
         when Semantic_Colour_Error =>
            return Editor.Syntax.Diagnostic_Error;
         when Semantic_Colour_Warning =>
            return Editor.Syntax.Diagnostic_Warning;
         when Semantic_Colour_Info =>
            return Editor.Syntax.Identifier;
      end case;
   end Token_For_Severity;

   procedure Add
     (Model    : in out Semantic_Colour_Model;
      Source   : Semantic_Colour_Source;
      Severity : Semantic_Colour_Severity;
      Node     : Editor.Ada_Syntax_Tree.Node_Id;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive;
      Start_Column : Positive;
      End_Line     : Positive;
      End_Column   : Positive;
      Fingerprint  : Natural)
   is
      Feed_Item : Semantic_Colour_Entry;
   begin
      Feed_Item.Id := Semantic_Colour_Entry_Id (Natural (Model.Entries.Length) + 1);
      Feed_Item.Source := Source;
      Feed_Item.Severity := Severity;
      Feed_Item.Token := Token_For_Severity (Severity);
      Feed_Item.Node := Node;
      Feed_Item.Message := Message;
      Feed_Item.Start_Line := Start_Line;
      Feed_Item.Start_Column := Start_Column;
      Feed_Item.End_Line := End_Line;
      Feed_Item.End_Column := End_Column;
      Feed_Item.Fingerprint := Mix
        (Fingerprint,
         Natural (Feed_Item.Id) + Semantic_Colour_Source'Pos (Source) * 31
           + Semantic_Colour_Severity'Pos (Severity) * 7);

      Model.Entries.Append (Feed_Item);
      case Severity is
         when Semantic_Colour_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Semantic_Colour_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Semantic_Colour_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
   end Add;

   function Convert
     (Severity : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Severity)
      return Semantic_Colour_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Error =>
            return Semantic_Colour_Error;
         when Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Warning =>
            return Semantic_Colour_Warning;
         when Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Severity_Info =>
            return Semantic_Colour_Info;
      end case;
   end Convert;

   function Convert
     (Severity : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Severity)
      return Semantic_Colour_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Error =>
            return Semantic_Colour_Error;
         when Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Warning =>
            return Semantic_Colour_Warning;
         when Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Severity_Info =>
            return Semantic_Colour_Info;
      end case;
   end Convert;

   function Convert
     (Severity : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Severity)
      return Semantic_Colour_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Error =>
            return Semantic_Colour_Error;
         when Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Warning =>
            return Semantic_Colour_Warning;
         when Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Severity_Info =>
            return Semantic_Colour_Info;
      end case;
   end Convert;

   function Convert
     (Severity : Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Severity)
      return Semantic_Colour_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Error =>
            return Semantic_Colour_Error;
         when Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Warning =>
            return Semantic_Colour_Warning;
         when Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Severity_Info =>
            return Semantic_Colour_Info;
      end case;
   end Convert;

   procedure Clear (Model : in out Semantic_Colour_Model) is
   begin
      Model.Entries.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Expressions     : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Generics        : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Cross_Units     : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Representation  : Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model)
      return Semantic_Colour_Model
   is
      Model : Semantic_Colour_Model;
   begin
      for Index in 1 .. Editor.Ada_Expression_Diagnostics.Diagnostic_Count (Expressions) loop
         declare
            D : constant Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Info :=
              Editor.Ada_Expression_Diagnostics.Diagnostic_At (Expressions, Index);
         begin
            Add (Model, Semantic_Colour_From_Expression, Convert (D.Severity),
                 D.Node, D.Message, D.Start_Line, D.Start_Column,
                 D.End_Line, D.End_Column, D.Fingerprint);
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_Count (Generics) loop
         declare
            D : constant Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Info :=
              Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_At (Generics, Index);
         begin
            Add (Model, Semantic_Colour_From_Generic_Contract, Convert (D.Severity),
                 D.Node, D.Message, D.Start_Line, D.Start_Column,
                 D.End_Line, D.End_Column, D.Fingerprint);
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Cross_Unit_Diagnostics.Diagnostic_Count (Cross_Units) loop
         declare
            D : constant Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Info :=
              Editor.Ada_Cross_Unit_Diagnostics.Diagnostic_At (Cross_Units, Index);
         begin
            Add (Model, Semantic_Colour_From_Cross_Unit, Convert (D.Severity),
                 Editor.Ada_Syntax_Tree.No_Node, D.Message, D.Start_Line,
                 D.Start_Column, D.End_Line, D.End_Column, D.Fingerprint);
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Representation_Diagnostics.Diagnostic_Count (Representation) loop
         declare
            D : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Info :=
              Editor.Ada_Representation_Diagnostics.Diagnostic_At (Representation, Index);
         begin
            Add (Model, Semantic_Colour_From_Representation, Convert (D.Severity),
                 D.Node, D.Message, D.Start_Line, D.Start_Column,
                 D.End_Line, D.End_Column, D.Fingerprint);
         end;
      end loop;

      return Model;
   end Build;

   function Entry_Count (Model : Semantic_Colour_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Semantic_Colour_Model;
      Index : Positive) return Semantic_Colour_Entry
   is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function Error_Count (Model : Semantic_Colour_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Semantic_Colour_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Semantic_Colour_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Count_Source
     (Model  : Semantic_Colour_Model;
      Source : Semantic_Colour_Source) return Natural
   is
      Count : Natural := 0;
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Source = Source then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Source;

   function Count_Token
     (Model : Semantic_Colour_Model;
      Token : Editor.Syntax.Token_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Feed_Item of Model.Entries loop
         if Feed_Item.Token = Token then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Token;

   function Fingerprint (Model : Semantic_Colour_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Semantic_Colour_Projection;
