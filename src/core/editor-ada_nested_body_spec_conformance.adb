with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Nested_Body_Spec_Conformance is

   use type Editor.Ada_Language_Model.Symbol_Id;
   use type Editor.Ada_Language_Model.Scope_Id;

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Normalize;

   procedure Mix (Value : in out Natural; Text : String) is
   begin
      for Ch of Text loop
         Value := (Value * 131 + Character'Pos (Ch)) mod 1_000_000_007;
      end loop;
   end Mix;

   procedure Mix (Value : in out Natural; N : Natural) is
   begin
      Value := (Value * 131 + N) mod 1_000_000_007;
   end Mix;

   function Confirmed_Unit
     (Info : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Info)
      return Boolean is
      use type Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Status;
   begin
      return Info.Status = Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Confirmed
        or else Info.Status = Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Package_Confirmed
        or else Info.Status = Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Subprogram_Profile_Confirmed;
   end Confirmed_Unit;

   function Conformance_Status
     (Spec : Editor.Ada_Language_Model.Symbol_Info;
      Body_Info : Editor.Ada_Language_Model.Symbol_Info;
      Candidate_Count : Natural) return Nested_Body_Spec_Conformance_Status is
      use type Editor.Ada_Language_Model.Symbol_Kind;
      Spec_Profile : constant String := Normalize (To_String (Spec.Profile_Summary));
      Body_Profile : constant String := Normalize (To_String (Body_Info.Profile_Summary));
   begin
      if Candidate_Count > 1 then
         return Nested_Body_Spec_Ambiguous_Body_Declaration;
      elsif Body_Info.Id = Editor.Ada_Language_Model.No_Symbol then
         return Nested_Body_Spec_Missing_Body_Declaration;
      elsif Spec.Kind /= Body_Info.Kind then
         return Nested_Body_Spec_Kind_Mismatch;
      elsif Spec.Kind = Editor.Ada_Language_Model.Symbol_Package
        or else Spec.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
        or else Spec.Kind = Editor.Ada_Language_Model.Symbol_Package_Body
      then
         return Nested_Body_Spec_Package_Confirmed;
      elsif Spec.Kind = Editor.Ada_Language_Model.Symbol_Procedure
        or else Spec.Kind = Editor.Ada_Language_Model.Symbol_Function
        or else Spec.Kind = Editor.Ada_Language_Model.Symbol_Operator_Function
        or else Spec.Kind = Editor.Ada_Language_Model.Symbol_Entry
        or else Spec.Kind = Editor.Ada_Language_Model.Symbol_Generic_Subprogram
      then
         if Spec_Profile = "" or else Body_Profile = "" then
            return Nested_Body_Spec_Profile_Unknown;
         elsif Spec_Profile = Body_Profile then
            return Nested_Body_Spec_Profile_Confirmed;
         else
            return Nested_Body_Spec_Profile_Mismatch;
         end if;
      else
         return Nested_Body_Spec_Confirmed;
      end if;
   end Conformance_Status;

   function Is_Nested_Conformance_Candidate
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Boolean is
      use type Editor.Ada_Language_Model.Symbol_Id;
   begin
      if Symbol.Id = Editor.Ada_Language_Model.No_Symbol then
         return False;
      end if;

      case Symbol.Kind is
         when Editor.Ada_Language_Model.Symbol_Package |
              Editor.Ada_Language_Model.Symbol_Package_Body |
              Editor.Ada_Language_Model.Symbol_Procedure |
              Editor.Ada_Language_Model.Symbol_Function |
              Editor.Ada_Language_Model.Symbol_Operator_Function |
              Editor.Ada_Language_Model.Symbol_Type |
              Editor.Ada_Language_Model.Symbol_Subtype |
              Editor.Ada_Language_Model.Symbol_Record_Type |
              Editor.Ada_Language_Model.Symbol_Object |
              Editor.Ada_Language_Model.Symbol_Constant |
              Editor.Ada_Language_Model.Symbol_Exception |
              Editor.Ada_Language_Model.Symbol_Task |
              Editor.Ada_Language_Model.Symbol_Protected |
              Editor.Ada_Language_Model.Symbol_Entry |
              Editor.Ada_Language_Model.Symbol_Generic_Package |
              Editor.Ada_Language_Model.Symbol_Generic_Subprogram |
              Editor.Ada_Language_Model.Symbol_Rename |
              Editor.Ada_Language_Model.Symbol_Instantiation =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Nested_Conformance_Candidate;

   function File_Position_For_Path
     (Index : Editor.Ada_Project_Index.Index_State;
      Path  : String) return Natural is
   begin
      for I in 1 .. Editor.Ada_Project_Index.File_Count (Index) loop
         if To_String (Editor.Ada_Project_Index.File_Key_At (Index, I).Path) = Path then
            return I;
         end if;
      end loop;
      return 0;
   end File_Position_For_Path;

   function Find_Unit_Symbol
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String) return Editor.Ada_Language_Model.Symbol_Info is
      Wanted : constant String := Normalize (Name);
   begin
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
         begin
            if Normalize (To_String (Symbol.Name)) = Wanted
              and then Symbol.Parent_Symbol = Editor.Ada_Language_Model.No_Symbol
            then
               return Symbol;
            end if;
         end;
      end loop;
      return (others => <>);
   end Find_Unit_Symbol;

   function Direct_Child
     (Child  : Editor.Ada_Language_Model.Symbol_Info;
      Parent : Editor.Ada_Language_Model.Symbol_Info) return Boolean is
   begin
      return Child.Parent_Symbol = Parent.Id
        and then Child.Enclosing_Scope = Editor.Ada_Language_Model.Scope_Id (Parent.Id)
        and then Child.Id /= Parent.Id;
   end Direct_Child;

   function Find_Body_Candidate
     (Analysis        : Editor.Ada_Language_Model.Analysis_Result;
      Body_Parent     : Editor.Ada_Language_Model.Symbol_Info;
      Name            : String;
      Candidate_Count : out Natural) return Editor.Ada_Language_Model.Symbol_Info is
      Wanted : constant String := Normalize (Name);
      Found  : Editor.Ada_Language_Model.Symbol_Info;
   begin
      Candidate_Count := 0;
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
         begin
            if Direct_Child (Symbol, Body_Parent)
              and then Is_Nested_Conformance_Candidate (Symbol)
              and then Normalize (To_String (Symbol.Name)) = Wanted
            then
               Candidate_Count := Candidate_Count + 1;
               if Candidate_Count = 1 then
                  Found := Symbol;
               end if;
            end if;
         end;
      end loop;
      if Candidate_Count = 1 then
         return Found;
      else
         return (others => <>);
      end if;
   end Find_Body_Candidate;

   function Has_Spec_Candidate
     (Analysis    : Editor.Ada_Language_Model.Analysis_Result;
      Spec_Parent : Editor.Ada_Language_Model.Symbol_Info;
      Name        : String) return Boolean is
      Wanted : constant String := Normalize (Name);
   begin
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
         begin
            if Direct_Child (Symbol, Spec_Parent)
              and then Is_Nested_Conformance_Candidate (Symbol)
              and then Normalize (To_String (Symbol.Name)) = Wanted
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Spec_Candidate;

   procedure Append_Info
     (Model       : in out Nested_Body_Spec_Conformance_Model;
      Unit_Index  : Natural;
      Unit_Info   : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Info;
      Status      : Nested_Body_Spec_Conformance_Status;
      Spec_Symbol : Editor.Ada_Language_Model.Symbol_Info;
      Body_Symbol : Editor.Ada_Language_Model.Symbol_Info;
      Name        : String;
      Candidates  : Natural) is
      Info : Nested_Body_Spec_Conformance_Info;
      FP   : Natural := 37;
   begin
      Info.Id := Nested_Conformance_Id (Natural (Model.Items.Length) + 1);
      Info.Status := Status;
      Info.Unit_Conformance := Unit_Index;
      Info.Spec_Unit_Name := Unit_Info.Spec_Unit_Name;
      Info.Body_Unit_Name := Unit_Info.Body_Unit_Name;
      Info.Spec_Path := Unit_Info.Spec_Path;
      Info.Body_Path := Unit_Info.Body_Path;
      Info.Spec_Symbol := Spec_Symbol.Id;
      Info.Body_Symbol := Body_Symbol.Id;
      Info.Declaration_Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize (Name));
      Info.Spec_Kind := Spec_Symbol.Kind;
      Info.Body_Kind := Body_Symbol.Kind;
      Info.Spec_Profile := Spec_Symbol.Profile_Summary;
      Info.Body_Profile := Body_Symbol.Profile_Summary;
      Info.Spec_Range := Spec_Symbol.Source_Span;
      Info.Body_Range := Body_Symbol.Source_Span;
      Info.Candidate_Count := Candidates;

      Mix (FP, Natural (Info.Id));
      Mix (FP, Nested_Body_Spec_Conformance_Status'Pos (Status));
      Mix (FP, Unit_Index);
      Mix (FP, To_String (Info.Spec_Unit_Name));
      Mix (FP, To_String (Info.Body_Unit_Name));
      Mix (FP, To_String (Info.Spec_Path));
      Mix (FP, To_String (Info.Body_Path));
      Mix (FP, Natural (Info.Spec_Symbol));
      Mix (FP, Natural (Info.Body_Symbol));
      Mix (FP, To_String (Info.Normalized_Name));
      Mix (FP, Editor.Ada_Language_Model.Symbol_Kind'Pos (Info.Spec_Kind));
      Mix (FP, Editor.Ada_Language_Model.Symbol_Kind'Pos (Info.Body_Kind));
      Mix (FP, To_String (Info.Spec_Profile));
      Mix (FP, To_String (Info.Body_Profile));
      Mix (FP, Candidates);
      Info.Fingerprint := FP;
      Model.Items.Append (Info);
      Mix (Model.Model_Fingerprint, FP);
   end Append_Info;

   function Build
     (Index       : Editor.Ada_Project_Index.Index_State;
      Conformance : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model)
      return Nested_Body_Spec_Conformance_Model is
      Model : Nested_Body_Spec_Conformance_Model;
   begin
      Model.Model_Fingerprint := 41;
      Mix (Model.Model_Fingerprint, Editor.Ada_Project_Index.Fingerprint (Index));
      Mix (Model.Model_Fingerprint, Editor.Ada_Body_Spec_Conformance.Fingerprint (Conformance));

      for C in 1 .. Editor.Ada_Body_Spec_Conformance.Conformance_Count (Conformance) loop
         declare
            Unit_Info : constant Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Info :=
              Editor.Ada_Body_Spec_Conformance.Conformance_At (Conformance, C);
            Spec_Pos : constant Natural := File_Position_For_Path (Index, To_String (Unit_Info.Spec_Path));
            Body_Pos : constant Natural := File_Position_For_Path (Index, To_String (Unit_Info.Body_Path));
         begin
            if not Confirmed_Unit (Unit_Info)
              or else Spec_Pos = 0
              or else Body_Pos = 0
            then
               Append_Info
                 (Model, C, Unit_Info, Nested_Body_Spec_Nonconforming_Unit_Pair,
                  (others => <>), (others => <>), To_String (Unit_Info.Spec_Unit_Name), 0);
            else
               declare
                  Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                    Editor.Ada_Project_Index.File_Analysis_At (Index, Spec_Pos);
                  Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                    Editor.Ada_Project_Index.File_Analysis_At (Index, Body_Pos);
                  Spec_Unit : constant Editor.Ada_Language_Model.Symbol_Info :=
                    Find_Unit_Symbol (Spec_Analysis, To_String (Unit_Info.Spec_Unit_Name));
                  Body_Unit : constant Editor.Ada_Language_Model.Symbol_Info :=
                    Find_Unit_Symbol (Body_Analysis, To_String (Unit_Info.Body_Unit_Name));
               begin
                  if Spec_Unit.Id = Editor.Ada_Language_Model.No_Symbol
                    or else Body_Unit.Id = Editor.Ada_Language_Model.No_Symbol
                  then
                     Append_Info
                       (Model, C, Unit_Info, Nested_Body_Spec_Nonconforming_Unit_Pair,
                        Spec_Unit, Body_Unit, To_String (Unit_Info.Spec_Unit_Name), 0);
                  else
                     for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Spec_Analysis) loop
                        declare
                           Spec_Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                             Editor.Ada_Language_Model.Symbol_At (Spec_Analysis, I);
                        begin
                           if Direct_Child (Spec_Symbol, Spec_Unit)
                             and then Is_Nested_Conformance_Candidate (Spec_Symbol)
                           then
                              declare
                                 Candidate_Count : Natural := 0;
                                 Body_Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                                   Find_Body_Candidate
                                     (Body_Analysis, Body_Unit,
                                      To_String (Spec_Symbol.Name), Candidate_Count);
                                 Status : constant Nested_Body_Spec_Conformance_Status :=
                                   Conformance_Status
                                     (Spec_Symbol, Body_Symbol, Candidate_Count);
                              begin
                                 Append_Info
                                   (Model, C, Unit_Info, Status, Spec_Symbol, Body_Symbol,
                                    To_String (Spec_Symbol.Name), Candidate_Count);
                              end;
                           end if;
                        end;
                     end loop;

                     for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Body_Analysis) loop
                        declare
                           Body_Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                             Editor.Ada_Language_Model.Symbol_At (Body_Analysis, I);
                        begin
                           if Direct_Child (Body_Symbol, Body_Unit)
                             and then Is_Nested_Conformance_Candidate (Body_Symbol)
                             and then not Has_Spec_Candidate
                               (Spec_Analysis, Spec_Unit, To_String (Body_Symbol.Name))
                           then
                              Append_Info
                                (Model, C, Unit_Info, Nested_Body_Spec_Extra_Body_Declaration,
                                 (others => <>), Body_Symbol,
                                 To_String (Body_Symbol.Name), 1);
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end if;
         end;
      end loop;

      return Model;
   end Build;

   function Conformance_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Conformance_Count;

   function Conformance_At
     (Model : Nested_Body_Spec_Conformance_Model;
      Index : Positive) return Nested_Body_Spec_Conformance_Info is
   begin
      if Model.Items.Is_Empty
        or else Index < Model.Items.First_Index
        or else Index > Model.Items.Last_Index
      then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Conformance_At;

   function First_For_Name
     (Model : Nested_Body_Spec_Conformance_Model;
      Name  : String) return Nested_Body_Spec_Conformance_Info is
      Wanted : constant String := Normalize (Name);
   begin
      for Info of Model.Items loop
         if To_String (Info.Normalized_Name) = Wanted then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Name;

   function Count_Status
     (Model  : Nested_Body_Spec_Conformance_Model;
      Status : Nested_Body_Spec_Conformance_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Confirmed_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Confirmed)
        + Count_Status (Model, Nested_Body_Spec_Profile_Confirmed)
        + Count_Status (Model, Nested_Body_Spec_Package_Confirmed);
   end Confirmed_Count;

   function Missing_Body_Declaration_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Missing_Body_Declaration);
   end Missing_Body_Declaration_Count;

   function Extra_Body_Declaration_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Extra_Body_Declaration);
   end Extra_Body_Declaration_Count;

   function Ambiguous_Body_Declaration_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Ambiguous_Body_Declaration);
   end Ambiguous_Body_Declaration_Count;

   function Kind_Mismatch_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Kind_Mismatch);
   end Kind_Mismatch_Count;

   function Profile_Mismatch_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Profile_Mismatch);
   end Profile_Mismatch_Count;

   function Profile_Unknown_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Profile_Unknown);
   end Profile_Unknown_Count;

   function Nonconforming_Unit_Pair_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Nested_Body_Spec_Nonconforming_Unit_Pair);
   end Nonconforming_Unit_Pair_Count;

   function Fingerprint
     (Model : Nested_Body_Spec_Conformance_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Nested_Body_Spec_Conformance;
