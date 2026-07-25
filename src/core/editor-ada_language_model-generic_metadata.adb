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

package body Editor.Ada_Language_Model.Generic_Metadata is

   pragma Suppress (Overflow_Check);

   procedure Add_Generic_Actual
     (Analysis        : in out Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Formal_Name     : String := "";
      Actual_Name     : String;
      Position        : Natural := 0;
      Source_Span           : Source_Range := (others => 1))
   is
      H : Natural := Analysis.Result_Fingerprint;
      Normal_Formal : constant String := Normalize_Name (Formal_Name);
      Normal_Actual : constant String := Normalize_Name (Actual_Name);
   begin
      if Instance_Symbol = No_Symbol or else Actual_Name'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Generic_Actuals.Length) >= Max_Generic_Actuals then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              Hash_Mix (Analysis.Result_Fingerprint, 579367);
         end if;
         return;
      end if;

      H := Hash_Mix (H, (Natural (Instance_Symbol), Position, 579367));
      H := Hash_String (H, Formal_Name);
      H := Hash_String (H, Normal_Formal);
      H := Hash_String (H, Actual_Name);
      H := Hash_String (H, Normal_Actual);
      H := Hash_Mix
        (H,
         (Source_Span.Start_Line,
          Source_Span.Start_Column,
          Source_Span.End_Line,
          Source_Span.End_Column));

      Analysis.Generic_Actuals.Append
        (Generic_Actual_Info'(Instance_Symbol => Instance_Symbol,
          Formal_Name => To_Unbounded_String (Formal_Name),
          Normalized_Formal_Name => To_Unbounded_String (Normal_Formal),
          Actual_Name => To_Unbounded_String (Actual_Name),
          Normalized_Actual_Name => To_Unbounded_String (Normal_Actual),
          Position => Position,
          Source_Span => Source_Span,
          Fingerprint => H));
      Analysis.Result_Fingerprint := H;
   end Add_Generic_Actual;


   function Generic_Actual_Count
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Actuals loop
         if Instance_Symbol = No_Symbol or else Info.Instance_Symbol = Instance_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Actual_Count;


   function Generic_Actual_At
     (Analysis        : Analysis_Result;
      Instance_Symbol : Symbol_Id;
      Index           : Positive) return Generic_Actual_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Actuals loop
         if Instance_Symbol = No_Symbol or else Info.Instance_Symbol = Instance_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Instance_Symbol => No_Symbol,
              Formal_Name => Null_Unbounded_String,
              Normalized_Formal_Name => Null_Unbounded_String,
              Actual_Name => Null_Unbounded_String,
              Normalized_Actual_Name => Null_Unbounded_String,
              Position => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Generic_Actual_At;


   procedure Add_Profile_Parameter_Metadata
     (Analysis                      : in out Analysis_Result;
      Owner_Symbol                  : Symbol_Id;
      Parameter_Symbol              : Symbol_Id;
      Name                          : String;
      Mode                          : Profile_Parameter_Mode;
      Type_Text                     : String := "";
      Has_Aliased                   : Boolean := False;
      Has_Access_Definition         : Boolean := False;
      Has_Access_Subprogram_Profile : Boolean := False;
      Has_Default_Expression        : Boolean := False;
      Default_Text                  : String := "";
      Group_Index                   : Natural := 0;
      Group_Position                : Natural := 0;
      Group_Name_Count              : Natural := 0;
      Source_Span                         : Source_Range := (others => 1))
   is
      Info : Profile_Parameter_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return;
      end if;

      if (Owner_Symbol /= No_Symbol
          and then Natural (Owner_Symbol) > Natural (Analysis.Symbols.Length))
        or else (Parameter_Symbol /= No_Symbol
                 and then Natural (Parameter_Symbol) > Natural (Analysis.Symbols.Length))
      then
         return;
      end if;

      if Natural (Analysis.Profile_Parameters.Length) >= Max_Profile_Parameters then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579744) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Owner_Symbol := Owner_Symbol;
      Info.Parameter_Symbol := Parameter_Symbol;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
      Info.Mode := Mode;
      Info.Type_Text := To_Unbounded_String (Type_Text);
      Info.Normalized_Type_Text := To_Unbounded_String (Normalize_Name (Type_Text));
      Info.Has_Aliased := Has_Aliased;
      Info.Has_Access_Definition := Has_Access_Definition;
      Info.Has_Access_Subprogram_Profile := Has_Access_Subprogram_Profile;
      Info.Has_Default_Expression := Has_Default_Expression;
      Info.Default_Text := To_Unbounded_String (Default_Text);
      Info.Group_Index := Group_Index;
      Info.Group_Position := Group_Position;
      Info.Group_Name_Count := Group_Name_Count;
      Info.Source_Span := Source_Span;

      H := (H * 131 + Natural (Owner_Symbol) + Natural (Parameter_Symbol)
            + Natural (Profile_Parameter_Mode'Pos (Mode)) + Group_Index
            + Group_Position + Group_Name_Count + 579744) mod 2_147_483_647;
      H := Hash_String (H, Name);
      H := Hash_String (H, Normalize_Name (Name));
      H := Hash_String (H, Type_Text);
      H := Hash_String (H, Normalize_Name (Type_Text));
      H := Hash_Boolean (H, Has_Aliased);
      H := Hash_Boolean (H, Has_Access_Definition);
      H := Hash_Boolean (H, Has_Access_Subprogram_Profile);
      H := Hash_Boolean (H, Has_Default_Expression);
      H := Hash_String (H, Default_Text);
      H := (H * 131 + Source_Span.Start_Line + Source_Span.Start_Column + Source_Span.End_Line
            + Source_Span.End_Column) mod 2_147_483_647;
      Info.Fingerprint := H;

      Analysis.Profile_Parameters.Append (Info);
      Analysis.Result_Fingerprint := H;
   end Add_Profile_Parameter_Metadata;


   function Profile_Parameter_Count
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Profile_Parameters loop
         if Owner_Symbol = No_Symbol or else Info.Owner_Symbol = Owner_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Profile_Parameter_Count;


   function Profile_Parameter_At
     (Analysis     : Analysis_Result;
      Owner_Symbol : Symbol_Id;
      Index        : Positive) return Profile_Parameter_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Profile_Parameters loop
         if Owner_Symbol = No_Symbol or else Info.Owner_Symbol = Owner_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Owner_Symbol => No_Symbol,
              Parameter_Symbol => No_Symbol,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Mode => Profile_Parameter_Default_In,
              Type_Text => Null_Unbounded_String,
              Normalized_Type_Text => Null_Unbounded_String,
              Has_Aliased => False,
              Has_Access_Definition => False,
              Has_Access_Subprogram_Profile => False,
              Has_Default_Expression => False,
              Default_Text => Null_Unbounded_String,
              Group_Index => 0,
              Group_Position => 0,
              Group_Name_Count => 0,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Profile_Parameter_At;


   procedure Add_Generic_Formal_Type_Metadata
     (Analysis                  : in out Analysis_Result;
      Formal_Symbol             : Symbol_Id;
      Name                      : String;
      Family                    : Generic_Formal_Type_Family;
      Target_Type_Text          : String := "";
      Profile_Text              : String := "";
      Has_Private               : Boolean := False;
      Has_Limited               : Boolean := False;
      Has_Tagged                : Boolean := False;
      Has_Abstract              : Boolean := False;
      Has_Synchronized          : Boolean := False;
      Has_Interface             : Boolean := False;
      Has_Box                   : Boolean := False;
      Has_Discriminant_Part     : Boolean := False;
      Source_Span                     : Source_Range := (others => 1))
   is
      Info : Generic_Formal_Type_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return;
      end if;

      if Formal_Symbol /= No_Symbol
        and then Natural (Formal_Symbol) > Natural (Analysis.Symbols.Length)
      then
         return;
      end if;

      if Natural (Analysis.Generic_Formal_Types.Length) >= Max_Generic_Formal_Types then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579745) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Formal_Symbol := Formal_Symbol;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
      Info.Family := Family;
      Info.Target_Type_Text := To_Unbounded_String (Target_Type_Text);
      Info.Normalized_Target_Type_Text :=
        To_Unbounded_String (Normalize_Name (Target_Type_Text));
      Info.Profile_Text := To_Unbounded_String (Profile_Text);
      Info.Has_Private := Has_Private;
      Info.Has_Limited := Has_Limited;
      Info.Has_Tagged := Has_Tagged;
      Info.Has_Abstract := Has_Abstract;
      Info.Has_Synchronized := Has_Synchronized;
      Info.Has_Interface := Has_Interface;
      Info.Has_Box := Has_Box;
      Info.Has_Discriminant_Part := Has_Discriminant_Part;
      Info.Source_Span := Source_Span;

      H := (H * 131 + Natural (Formal_Symbol)
            + Natural (Generic_Formal_Type_Family'Pos (Family)) + 579745)
        mod 2_147_483_647;
      H := Hash_String (H, Name);
      H := Hash_String (H, Normalize_Name (Name));
      H := Hash_String (H, Target_Type_Text);
      H := Hash_String (H, Normalize_Name (Target_Type_Text));
      H := Hash_String (H, Profile_Text);
      H := Hash_Boolean (H, Has_Private);
      H := Hash_Boolean (H, Has_Limited);
      H := Hash_Boolean (H, Has_Tagged);
      H := Hash_Boolean (H, Has_Abstract);
      H := Hash_Boolean (H, Has_Synchronized);
      H := Hash_Boolean (H, Has_Interface);
      H := Hash_Boolean (H, Has_Box);
      H := Hash_Boolean (H, Has_Discriminant_Part);
      H := (H * 131 + Source_Span.Start_Line + Source_Span.Start_Column
            + Source_Span.End_Line + Source_Span.End_Column) mod 2_147_483_647;
      Info.Fingerprint := H;

      Analysis.Generic_Formal_Types.Append (Info);
      Analysis.Result_Fingerprint := H;
   end Add_Generic_Formal_Type_Metadata;


   function Generic_Formal_Type_Metadata_Count
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id := No_Symbol) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Formal_Types loop
         if Formal_Symbol = No_Symbol or else Info.Formal_Symbol = Formal_Symbol then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Formal_Type_Metadata_Count;


   function Generic_Formal_Type_Metadata_At
     (Analysis      : Analysis_Result;
      Formal_Symbol : Symbol_Id;
      Index         : Positive) return Generic_Formal_Type_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Generic_Formal_Types loop
         if Formal_Symbol = No_Symbol or else Info.Formal_Symbol = Formal_Symbol then
            Count := Count + 1;
            if Count = Index then
               return Info;
            end if;
         end if;
      end loop;

      return (Formal_Symbol => No_Symbol,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Family => Generic_Formal_Type_Unknown,
              Target_Type_Text => Null_Unbounded_String,
              Normalized_Target_Type_Text => Null_Unbounded_String,
              Profile_Text => Null_Unbounded_String,
              Has_Private => False,
              Has_Limited => False,
              Has_Tagged => False,
              Has_Abstract => False,
              Has_Synchronized => False,
              Has_Interface => False,
              Has_Box => False,
              Has_Discriminant_Part => False,
              Source_Span => (1, 1, 1, 1),
              Fingerprint => 0);
   end Generic_Formal_Type_Metadata_At;



   procedure Add_Pragma_Metadata
     (Analysis             : in out Analysis_Result;
      Name                 : String;
      Placement            : Pragma_Placement_Kind;
      Scope                : Scope_Id := Root_Scope;
      Target_Name          : String := "";
      Argument_Count       : Natural := 0;
      Named_Argument_Count : Natural := 0;
      Source_Span                : Source_Range := (others => 1))
   is
      Info : Pragma_Info;
      H    : Natural := Analysis.Result_Fingerprint;
   begin
      if Name'Length = 0 then
         return;
      end if;

      if Natural (Analysis.Pragmas.Length) >= Max_Pragmas then
         if not Analysis.Symbol_Overflow then
            Analysis.Symbol_Overflow := True;
            Analysis.Result_Fingerprint :=
              (Analysis.Result_Fingerprint * 131 + 579729) mod 2_147_483_647;
         end if;
         return;
      end if;

      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize_Name (Name));
      Info.Placement := Placement;
      Info.Scope := Scope;
      Info.Target_Name := To_Unbounded_String (Target_Name);
      Info.Normalized_Target_Name := To_Unbounded_String (Normalize_Name (Target_Name));
      Info.Argument_Count := Argument_Count;
      Info.Named_Argument_Count := Named_Argument_Count;
      Info.Source_Span := Source_Span;

      H := Hash_String (H, Normalize_Name (Name));
      H := Hash_String (H, Pragma_Placement_Kind'Image (Placement));
      H := Hash_String (H, Normalize_Name (Target_Name));
      H := (H * 131 + Natural (Scope) + Argument_Count + Named_Argument_Count
            + Source_Span.Start_Line + Source_Span.Start_Column + Source_Span.End_Line
            + Source_Span.End_Column) mod 2_147_483_647;
      Info.Fingerprint := H;

      Analysis.Pragmas.Append (Info);
      Analysis.Result_Fingerprint := H;
   end Add_Pragma_Metadata;

   function Pragma_Metadata_Count
     (Analysis  : Analysis_Result;
      Placement : Pragma_Placement_Kind := Pragma_Placement_Declaration;
      Any_Placement : Boolean := True) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Pragmas loop
         if Any_Placement or else Info.Placement = Placement then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Pragma_Metadata_Count;

   function Pragma_Metadata_At
     (Analysis  : Analysis_Result;
      Index     : Positive) return Pragma_Info
   is
      Count : Natural := 0;
   begin
      for Info of Analysis.Pragmas loop
         Count := Count + 1;
         if Count = Index then
            return Info;
         end if;
      end loop;

      return (Name => To_Unbounded_String (""),
              Normalized_Name => To_Unbounded_String (""),
              Placement => Pragma_Placement_Declaration,
              Scope => Root_Scope,
              Target_Name => To_Unbounded_String (""),
              Normalized_Target_Name => To_Unbounded_String (""),
              Argument_Count => 0,
              Named_Argument_Count => 0,
              Source_Span => (others => 1),
              Fingerprint => 0);
   end Pragma_Metadata_At;


end Editor.Ada_Language_Model.Generic_Metadata;
