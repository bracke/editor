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

package body Editor.Ada_Language_Model.Representation_Metadata is

   pragma Suppress (Overflow_Check);

   procedure Add_Representation_Clause
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id := No_Symbol;
      Target_Name       : String;
      Kind              : Representation_Clause_Kind;
      Attribute_Name    : String := "";
      Item_Text         : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Attribute_Definition;
      Has_Static_Value  : Boolean := False;
      Static_Value      : Natural := 0;
      Source_Span             : Source_Range)
   is
      Info : Representation_Clause_Info;
      Flags : Declaration_Flags := (others => False);
      H : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol and then Target_Name'Length = 0 then
         return;
      end if;

      if Target_Symbol /= No_Symbol
        and then Natural (Target_Symbol) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      if Natural (Analysis.Representation_Clauses.Length) >= Max_Representation_Clauses then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579371) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Target_Symbol := Target_Symbol;
      Info.Target_Name := To_Unbounded_String (Target_Name);
      Info.Normalized_Target_Name := To_Unbounded_String (Normalize_Name (Target_Name));
      Info.Kind := Kind;
      Info.Attribute_Name := To_Unbounded_String (Attribute_Name);
      Info.Item_Text := To_Unbounded_String (Item_Text);
      Info.Source_Form := Source_Form;
      Info.Has_Static_Value := Has_Static_Value;
      Info.Static_Value := Static_Value;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Target_Name);
      H := Hash_String (H, Attribute_Name);
      H := Hash_String (H, Item_Text);
      H := (H * 131 + Natural (Target_Symbol) + Representation_Clause_Kind'Pos (Kind) + 579372)
        mod 2_147_483_647;
      H := (H * 131 + Representation_Source_Form'Pos (Source_Form) + 579377)
        mod 2_147_483_647;
      if Has_Static_Value then
         H := (H * 131 + Static_Value + 23) mod 2_147_483_647;
      end if;
      Info.Fingerprint := H;

      Analysis.Representation_Clauses.Append (Info);
      Flags.Has_Representation_Clause := True;
      if Target_Symbol /= No_Symbol then
         Merge_Symbol_Flags (Analysis, Target_Symbol, Flags);
      end if;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579373) mod 2_147_483_647;
   end Add_Representation_Clause;


   function Representation_Clause_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Clauses loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Clause_Count;


   function Representation_Clause_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Clause_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Clauses loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Target_Name => Null_Unbounded_String,
              Normalized_Target_Name => Null_Unbounded_String,
              Kind => Representation_Other_Clause,
              Attribute_Name => Null_Unbounded_String,
              Item_Text => Null_Unbounded_String,
              Source_Form => Representation_Source_Attribute_Definition,
              Has_Static_Value => False,
              Static_Value => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Representation_Clause_At;


   procedure Add_Enumeration_Representation_Literal
     (Analysis         : in out Analysis_Result;
      Target_Symbol    : Symbol_Id;
      Literal_Symbol   : Symbol_Id := No_Symbol;
      Literal_Name     : String;
      Value_Text       : String;
      Has_Static_Value : Boolean := False;
      Static_Value     : Natural := 0;
      Source_Span            : Source_Range)
   is
      Info : Enumeration_Representation_Literal_Info;
      Flags : Declaration_Flags := (others => False);
      H : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol or else Literal_Name'Length = 0 then
         return;
      end if;

      if Natural (Target_Symbol) > Natural (Analysis.Symbols.Length) then
         return;
      end if;

      if Natural (Analysis.Enumeration_Representation_Literals.Length) >= Max_Enumeration_Representation_Literals then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579374) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Target_Symbol := Target_Symbol;
      Info.Literal_Symbol := Literal_Symbol;
      Info.Literal_Name := To_Unbounded_String (Literal_Name);
      Info.Value_Text := To_Unbounded_String (Value_Text);
      Info.Has_Static_Value := Has_Static_Value;
      Info.Static_Value := Static_Value;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Literal_Name);
      H := Hash_String (H, Value_Text);
      H := (H * 131 + Natural (Target_Symbol) + Natural (Literal_Symbol) + 579375)
        mod 2_147_483_647;
      if Has_Static_Value then
         H := (H * 131 + Static_Value + 29) mod 2_147_483_647;
      end if;
      Info.Fingerprint := H;

      Analysis.Enumeration_Representation_Literals.Append (Info);
      Flags.Has_Representation_Clause := True;
      Merge_Symbol_Flags (Analysis, Target_Symbol, Flags);
      if Literal_Symbol /= No_Symbol then
         Merge_Symbol_Flags (Analysis, Literal_Symbol, Flags);
      end if;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579376) mod 2_147_483_647;
   end Add_Enumeration_Representation_Literal;


   function Enumeration_Representation_Literal_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Enumeration_Representation_Literals loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Enumeration_Representation_Literal_Count;


   function Enumeration_Representation_Literal_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Enumeration_Representation_Literal_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Enumeration_Representation_Literals loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Literal_Symbol => No_Symbol,
              Literal_Name => Null_Unbounded_String,
              Value_Text => Null_Unbounded_String,
              Has_Static_Value => False,
              Static_Value => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Enumeration_Representation_Literal_At;

   procedure Add_Record_Representation_Component
     (Analysis          : in out Analysis_Result;
      Target_Symbol     : Symbol_Id;
      Component_Symbol  : Symbol_Id := No_Symbol;
      Component_Name    : String;
      Storage_Unit_Text : String;
      First_Bit_Text    : String;
      Last_Bit_Text     : String;
      Source_Form       : Representation_Source_Form :=
        Representation_Source_Record_Component_Clause;
      Has_Static_Storage_Unit : Boolean := False;
      Static_Storage_Unit     : Natural := 0;
      Has_Static_First_Bit    : Boolean := False;
      Static_First_Bit        : Natural := 0;
      Has_Static_Last_Bit     : Boolean := False;
      Static_Last_Bit         : Natural := 0;
      Source_Span             : Source_Range)
   is
      Info : Representation_Component_Info;
      Flags : Declaration_Flags := (others => False);
      H : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol or else Component_Name'Length = 0 then
         return;
      end if;

      if Natural (Target_Symbol) > Natural (Analysis.Symbols.Length) then
         return;
      end if;

      if Natural (Analysis.Representation_Components.Length) >= Max_Representation_Components then
         --  Record layout metadata is analysis-owned and bounded just like
         --  symbols.  Overflow is exposed through the existing analysis
         --  overflow/fingerprint state so semantic and outline users can
         --  degrade deterministically instead of retaining unbounded layout
         --  rows from very large generated specs.
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579360) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Target_Symbol := Target_Symbol;
      Info.Component_Symbol := Component_Symbol;
      Info.Component_Name := To_Unbounded_String (Component_Name);
      Info.Storage_Unit_Text := To_Unbounded_String (Storage_Unit_Text);
      Info.First_Bit_Text := To_Unbounded_String (First_Bit_Text);
      Info.Last_Bit_Text := To_Unbounded_String (Last_Bit_Text);
      Info.Source_Form := Source_Form;
      Info.Has_Static_Storage_Unit := Has_Static_Storage_Unit;
      Info.Static_Storage_Unit := Static_Storage_Unit;
      Info.Has_Static_First_Bit := Has_Static_First_Bit;
      Info.Static_First_Bit := Static_First_Bit;
      Info.Has_Static_Last_Bit := Has_Static_Last_Bit;
      Info.Static_Last_Bit := Static_Last_Bit;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Component_Name);
      H := Hash_String (H, Storage_Unit_Text);
      H := Hash_String (H, First_Bit_Text);
      H := Hash_String (H, Last_Bit_Text);
      H := (H * 131 + Natural (Target_Symbol) + Natural (Component_Symbol) + 579351)
        mod 2_147_483_647;
      H := (H * 131 + Representation_Source_Form'Pos (Source_Form) + 579353)
        mod 2_147_483_647;
      if Has_Static_Storage_Unit then
         H := (H * 131 + Static_Storage_Unit + 11) mod 2_147_483_647;
      end if;
      if Has_Static_First_Bit then
         H := (H * 131 + Static_First_Bit + 13) mod 2_147_483_647;
      end if;
      if Has_Static_Last_Bit then
         H := (H * 131 + Static_Last_Bit + 17) mod 2_147_483_647;
      end if;
      Info.Fingerprint := H;

      Analysis.Representation_Components.Append (Info);
      Flags.Has_Representation_Clause := True;
      Merge_Symbol_Flags (Analysis, Target_Symbol, Flags);
      if Component_Symbol /= No_Symbol then
         Merge_Symbol_Flags (Analysis, Component_Symbol, Flags);
      end if;
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579352) mod 2_147_483_647;
   end Add_Record_Representation_Component;


   function Representation_Component_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Components loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Component_Count;


   function Representation_Component_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Representation_Component_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Representation_Components loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Component_Symbol => No_Symbol,
              Component_Name => Null_Unbounded_String,
              Storage_Unit_Text => Null_Unbounded_String,
              First_Bit_Text => Null_Unbounded_String,
              Last_Bit_Text => Null_Unbounded_String,
              Source_Form => Representation_Source_Record_Component_Clause,
              Has_Static_Storage_Unit => False,
              Static_Storage_Unit => 0,
              Has_Static_First_Bit => False,
              Static_First_Bit => 0,
              Has_Static_Last_Bit => False,
              Static_Last_Bit => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Representation_Component_At;



   procedure Add_Freezing_Point
     (Analysis       : in out Analysis_Result;
      Target_Symbol  : Symbol_Id;
      Trigger_Symbol : Symbol_Id;
      Kind           : Freezing_Point_Kind;
      Reason         : String;
      Source_Span          : Source_Range)
   is
      Info : Freezing_Point_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Target_Symbol = No_Symbol or else Reason'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Freezing_Points.Length) >= Max_Freezing_Points then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579458) mod 2_147_483_647;
         end if;
         return;
      end if;

      --  Avoid recording the same bounded freezing trigger more than once;
      --  diagnostics may inspect multiple representation clauses for one
      --  target.
      for Existing of Analysis.Freezing_Points loop
         if Existing.Target_Symbol = Target_Symbol
           and then Existing.Trigger_Symbol = Trigger_Symbol
           and then Existing.Kind = Kind
           and then Existing.Source_Span.Start_Line = Source_Span.Start_Line
         then
            return;
         end if;
      end loop;

      Info.Target_Symbol := Target_Symbol;
      Info.Trigger_Symbol := Trigger_Symbol;
      Info.Kind := Kind;
      Info.Reason := To_Unbounded_String (Reason);
      Info.Source_Span := Source_Span;
      H := (H * 131 + Natural (Target_Symbol) + Natural (Trigger_Symbol) + 579459)
        mod 2_147_483_647;
      H := (H * 131 + Natural (Freezing_Point_Kind'Pos (Kind)) + 7)
        mod 2_147_483_647;
      H := Hash_String (H, Reason);
      Info.Fingerprint := H;
      Analysis.Freezing_Points.Append (Info);
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 131 + H + 579460) mod 2_147_483_647;
   end Add_Freezing_Point;


   function Freezing_Point_Count
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Freezing_Points loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Freezing_Point_Count;


   function Freezing_Point_At
     (Analysis      : Analysis_Result;
      Target_Symbol : Symbol_Id;
      Index         : Positive) return Freezing_Point_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Freezing_Points loop
         if Target_Symbol = No_Symbol or else Info.Target_Symbol = Target_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Target_Symbol => No_Symbol,
              Trigger_Symbol => No_Symbol,
              Kind => Freezing_First_Use,
              Reason => Null_Unbounded_String,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Freezing_Point_At;



end Editor.Ada_Language_Model.Representation_Metadata;
