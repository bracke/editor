with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Instance_Freezing_Representation_Legality is

   pragma Suppress (Overflow_Check);

   package AL renames Editor.Ada_Assignment_Legality;
   package RL renames Editor.Ada_Return_Legality;
   package EL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   package TD renames Editor.Ada_Tagged_Derived_Legality;
   package GB renames Editor.Ada_Generic_Instantiated_Body_Analysis;
   package FP renames Editor.Ada_Generic_Formal_Package_Substitutions;
   package FR renames Editor.Ada_Freezing_Points;
   package RP renames Editor.Ada_Representation_Legality;

   use type AL.Assignment_Context_Id;
   use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type EL.Semantic_Context_Id;
   use type FR.Freezable_Id;
   use type FR.Freezing_Cause;
   use type FR.Representation_Freezing_Status;
   use type FR.Freezing_Status;
   use type RL.Return_Context_Id;
   use type RP.Representation_Legality_Status;
   use type TD.Tagged_Context_Id;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 1_315_423_911
        + Hash_Value (Right) * 2_654_435_761
        + 97;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Normalize (Value : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Value)));
   end Normalize;

   function Kind_Slot (Kind : Instance_Context_Kind) return Natural is
   begin
      return Instance_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Instance_Legality_Status) return Natural is
   begin
      return Instance_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Context_Fingerprint (Context : Instance_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Node) + 1);
      H := Mix (H, Natural (Context.Instance_Node) + 1);
      H := Mix (H, Natural (Context.Formal_Node) + 1);
      H := Mix (H, Natural (Context.Body_Node) + 1);
      H := Mix (H, Natural (Context.Representation_Node) + 1);
      H := Mix (H, Natural (Context.Instance) + 1);
      H := Mix (H, Natural (Context.Formal) + 1);
      H := Mix (H, Natural (Context.Body_Substitution) + 1);
      H := Mix (H, Natural (Context.Formal_Package_Substitution) + 1);
      H := Mix (H, Natural (Context.Freezable) + 1);
      H := Mix (H, Length (Context.Normalized_Instance_Name) + 1);
      H := Mix (H, Length (Context.Normalized_Target_Name) + 1);
      H := Mix (H, GB.Instantiated_Body_Status'Pos (Context.Body_Status) + 1);
      H := Mix (H, FP.Formal_Package_Substitution_Status'Pos (Context.Formal_Package_Status) + 1);
      H := Mix (H, FR.Freezing_Status'Pos (Context.Freeze_Status) + 1);
      H := Mix (H, RP.Representation_Legality_Status'Pos (Context.Representation_Status) + 1);
      H := Mix (H, Boolean'Pos (Context.Instance_Freezes_Target) + 1);
      H := Mix (H, Boolean'Pos (Context.Representation_After_Instance_Freezing) + 1);
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      H := Mix (H, Context.Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Legality_Fingerprint (Info : Instance_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Instance_Node) + 1);
      H := Mix (H, Natural (Info.Formal_Node) + 1);
      H := Mix (H, Natural (Info.Body_Node) + 1);
      H := Mix (H, Natural (Info.Representation_Node) + 1);
      H := Mix (H, Natural (Info.Instance) + 1);
      H := Mix (H, Natural (Info.Formal) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Normalized_Instance_Name) + 1);
      H := Mix (H, Length (Info.Normalized_Target_Name) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Legality_Fingerprint;

   function Is_Legal_Status (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status in Instance_Legality_Legal_Instance |
        Instance_Legality_Legal_Body_Substitution |
        Instance_Legality_Legal_Default_Substitution |
        Instance_Legality_Legal_Formal_Package_Substitution |
        Instance_Legality_Legal_Boxed_Formal_Package |
        Instance_Legality_Legal_Instance_Freezing |
        Instance_Legality_Legal_Representation_Item;
   end Is_Legal_Status;

   function Is_Warning_Status (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status in Instance_Legality_Body_Object_Unknown |
        Instance_Legality_Instance_Freezes_Target |
        Instance_Legality_Unknown;
   end Is_Warning_Status;

   function Is_Body_Error (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status in Instance_Legality_Body_Private_View_Barrier |
        Instance_Legality_Body_Limited_View_Barrier |
        Instance_Legality_Body_Cross_Unit_Unresolved |
        Instance_Legality_Body_Object_Mismatch |
        Instance_Legality_Missing_Body_Contract |
        Instance_Legality_Body_Contract_Mismatch;
   end Is_Body_Error;

   function Is_Formal_Package_Error (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status in Instance_Legality_Formal_Package_Mismatch |
        Instance_Legality_Formal_Package_Missing |
        Instance_Legality_Formal_Package_Wrong_Generic |
        Instance_Legality_Formal_Package_Unresolved |
        Instance_Legality_Formal_Package_Malformed;
   end Is_Formal_Package_Error;

   function Is_Freezing_Error (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status = Instance_Legality_Representation_After_Instance_Freezing;
   end Is_Freezing_Error;

   function Is_Representation_Error (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status in Instance_Legality_Representation_Target_Unresolved |
        Instance_Legality_Representation_Target_Ambiguous |
        Instance_Legality_Representation_Target_Kind_Mismatch |
        Instance_Legality_Representation_Static_Error |
        Instance_Legality_Representation_Profile_Error |
        Instance_Legality_Representation_Operational_Error;
   end Is_Representation_Error;

   function Is_Linked_Error (Status : Instance_Legality_Status) return Boolean is
   begin
      return Status in Instance_Legality_Assignment_Error |
        Instance_Legality_Return_Error |
        Instance_Legality_Conversion_Access_Aggregate_Error |
        Instance_Legality_Tagged_Derived_Error;
   end Is_Linked_Error;

   function Assignment_Error
     (Assignments : AL.Assignment_Legality_Model;
      Context     : AL.Assignment_Context_Id) return Boolean
   is
      Info : AL.Assignment_Legality_Info;
   begin
      if Context = AL.No_Assignment_Context then
         return False;
      end if;

      Info := AL.First_For_Context (Assignments, Context);
      return Info.Context /= AL.No_Assignment_Context
        and then Info.Status not in AL.Assignment_Legality_Compatible |
          AL.Assignment_Legality_Class_Wide_Compatible |
          AL.Assignment_Legality_Static_Range_Compatible;
   end Assignment_Error;

   function Return_Error
     (Returns : RL.Return_Legality_Model;
      Context : RL.Return_Context_Id) return Boolean
   is
      Info : RL.Return_Legality_Info;
   begin
      if Context = RL.No_Return_Context then
         return False;
      end if;

      Info := RL.First_For_Context (Returns, Context);
      return Info.Context /= RL.No_Return_Context
        and then Info.Status not in RL.Return_Legality_Procedure_Return_Compatible |
          RL.Return_Legality_Function_Return_Compatible |
          RL.Return_Legality_Extended_Return_Compatible;
   end Return_Error;

   function Expression_Error
     (Expressions : EL.Semantic_Legality_Model;
      Context     : EL.Semantic_Context_Id) return Boolean
   is
      Info : EL.Semantic_Legality_Info;
   begin
      if Context = EL.No_Semantic_Context then
         return False;
      end if;

      Info := EL.First_For_Context (Expressions, Context);
      return Info.Context /= EL.No_Semantic_Context
        and then Info.Status not in EL.Semantic_Legality_Legal_Conversion |
          EL.Semantic_Legality_Legal_Qualified_Expression |
          EL.Semantic_Legality_Legal_Access_Conversion |
          EL.Semantic_Legality_Legal_Access_Parameter |
          EL.Semantic_Legality_Legal_Allocator |
          EL.Semantic_Legality_Legal_Aggregate |
          EL.Semantic_Legality_Legal_Container_Aggregate |
          EL.Semantic_Legality_Numeric_Conversion |
          EL.Semantic_Legality_Tagged_Conversion |
          EL.Semantic_Legality_Class_Wide_Conversion |
          EL.Semantic_Legality_Static_Range_Compatible;
   end Expression_Error;

   function Tagged_Error
     (Tagged_Model : TD.Tagged_Legality_Model;
      Context : TD.Tagged_Context_Id) return Boolean
   is
      Info : TD.Tagged_Legality_Info;
   begin
      if Context = TD.No_Tagged_Context then
         return False;
      end if;

      Info := TD.First_For_Context (Tagged_Model, Context);
      return Info.Context /= TD.No_Tagged_Context
        and then Info.Status not in TD.Tagged_Legality_Legal_Derivation |
          TD.Tagged_Legality_Legal_Private_Extension |
          TD.Tagged_Legality_Legal_Interface_Derivation |
          TD.Tagged_Legality_Legal_Primitive_Operation |
          TD.Tagged_Legality_Legal_Override |
          TD.Tagged_Legality_Legal_Abstract_Type |
          TD.Tagged_Legality_Legal_Dispatching_Call |
          TD.Tagged_Legality_Legal_Class_Wide_Conversion;
   end Tagged_Error;

   function Body_Status_To_Instance
     (Status : GB.Instantiated_Body_Status) return Instance_Legality_Status is
   begin
      case Status is
         when GB.Instantiated_Body_Substituted =>
            return Instance_Legality_Legal_Body_Substitution;
         when GB.Instantiated_Body_Default_Substituted =>
            return Instance_Legality_Legal_Default_Substitution;
         when GB.Instantiated_Body_Private_View_Barrier =>
            return Instance_Legality_Body_Private_View_Barrier;
         when GB.Instantiated_Body_Limited_View_Barrier =>
            return Instance_Legality_Body_Limited_View_Barrier;
         when GB.Instantiated_Body_Cross_Unit_Unresolved =>
            return Instance_Legality_Body_Cross_Unit_Unresolved;
         when GB.Instantiated_Body_Object_Mismatch =>
            return Instance_Legality_Body_Object_Mismatch;
         when GB.Instantiated_Body_Object_Unknown =>
            return Instance_Legality_Body_Object_Unknown;
         when GB.Instantiated_Body_No_Body_Contract =>
            return Instance_Legality_Missing_Body_Contract;
         when GB.Instantiated_Body_Contract_Mismatch =>
            return Instance_Legality_Body_Contract_Mismatch;
         when GB.Instantiated_Body_Not_Checked | GB.Instantiated_Body_Unknown =>
            return Instance_Legality_Unknown;
      end case;
   end Body_Status_To_Instance;

   function Formal_Package_Status_To_Instance
     (Status : FP.Formal_Package_Substitution_Status) return Instance_Legality_Status is
   begin
      case Status is
         when FP.Formal_Package_Substitution_Substituted =>
            return Instance_Legality_Legal_Formal_Package_Substitution;
         when FP.Formal_Package_Substitution_Boxed =>
            return Instance_Legality_Legal_Boxed_Formal_Package;
         when FP.Formal_Package_Substitution_Mismatch =>
            return Instance_Legality_Formal_Package_Mismatch;
         when FP.Formal_Package_Substitution_Missing =>
            return Instance_Legality_Formal_Package_Missing;
         when FP.Formal_Package_Substitution_Wrong_Generic =>
            return Instance_Legality_Formal_Package_Wrong_Generic;
         when FP.Formal_Package_Substitution_Unresolved =>
            return Instance_Legality_Formal_Package_Unresolved;
         when FP.Formal_Package_Substitution_Malformed =>
            return Instance_Legality_Formal_Package_Malformed;
         when FP.Formal_Package_Substitution_Not_Checked |
              FP.Formal_Package_Substitution_Unknown =>
            return Instance_Legality_Unknown;
      end case;
   end Formal_Package_Status_To_Instance;

   function Representation_Status_To_Instance
     (Status : RP.Representation_Legality_Status) return Instance_Legality_Status is
   begin
      case Status is
         when RP.Representation_Legality_Ok |
              RP.Representation_Legality_At_Freezing_Point =>
            return Instance_Legality_Legal_Representation_Item;
         when RP.Representation_Legality_After_Freezing =>
            return Instance_Legality_Representation_After_Instance_Freezing;
         when RP.Representation_Legality_Target_Unresolved =>
            return Instance_Legality_Representation_Target_Unresolved;
         when RP.Representation_Legality_Target_Ambiguous =>
            return Instance_Legality_Representation_Target_Ambiguous;
         when RP.Representation_Legality_Target_Kind_Mismatch |
              RP.Representation_Legality_Target_Not_Freezable =>
            return Instance_Legality_Representation_Target_Kind_Mismatch;
         when RP.Representation_Legality_Static_Value_Required |
              RP.Representation_Legality_Static_Value_Malformed |
              RP.Representation_Legality_Static_Value_Division_By_Zero |
              RP.Representation_Legality_Static_Value_Not_Positive |
              RP.Representation_Legality_Static_Value_Not_Integer |
              RP.Representation_Legality_Record_Component_Static_Value_Required |
              RP.Representation_Legality_Enumeration_Value_Static_Required =>
            return Instance_Legality_Representation_Static_Error;
         when RP.Representation_Legality_Stream_Subprogram_Profile_Unknown |
              RP.Representation_Legality_Stream_Subprogram_Profile_Mismatch |
              RP.Representation_Legality_Stream_Subprogram_Required |
              RP.Representation_Legality_Stream_Subprogram_Malformed =>
            return Instance_Legality_Representation_Profile_Error;
         when RP.Representation_Legality_Operational_Target_Incompatible |
              RP.Representation_Legality_Operational_Boolean_Value_Required |
              RP.Representation_Legality_Operational_Order_Value_Required =>
            return Instance_Legality_Representation_Operational_Error;
         when others =>
            return Instance_Legality_Representation_Target_Kind_Mismatch;
      end case;
   end Representation_Status_To_Instance;

   function Message_For (Status : Instance_Legality_Status) return String is
   begin
      case Status is
         when Instance_Legality_Legal_Instance => return "generic instance is semantically closed";
         when Instance_Legality_Legal_Body_Substitution => return "generic body substitution is legal";
         when Instance_Legality_Legal_Default_Substitution => return "defaulted generic body substitution is legal";
         when Instance_Legality_Legal_Formal_Package_Substitution => return "formal package substitution is legal";
         when Instance_Legality_Legal_Boxed_Formal_Package => return "boxed formal package substitution is legal";
         when Instance_Legality_Legal_Instance_Freezing => return "generic instance freezing effect is legal";
         when Instance_Legality_Legal_Representation_Item => return "representation item remains legal for generic instance";
         when Instance_Legality_Body_Private_View_Barrier => return "generic body substitution crosses a private view barrier";
         when Instance_Legality_Body_Limited_View_Barrier => return "generic body substitution crosses a limited view barrier";
         when Instance_Legality_Body_Cross_Unit_Unresolved => return "generic body substitution has unresolved cross-unit view";
         when Instance_Legality_Body_Object_Mismatch => return "generic body substitution object type mismatches formal contract";
         when Instance_Legality_Body_Object_Unknown => return "generic body substitution object compatibility is unknown";
         when Instance_Legality_Missing_Body_Contract => return "generic instance has no matching body contract";
         when Instance_Legality_Body_Contract_Mismatch => return "generic body contract does not match instance";
         when Instance_Legality_Formal_Package_Mismatch => return "formal package nested actual mismatches";
         when Instance_Legality_Formal_Package_Missing => return "formal package nested actual is missing";
         when Instance_Legality_Formal_Package_Wrong_Generic => return "formal package actual names the wrong generic";
         when Instance_Legality_Formal_Package_Unresolved => return "formal package actual is unresolved";
         when Instance_Legality_Formal_Package_Malformed => return "formal package actual is malformed";
         when Instance_Legality_Instance_Freezes_Target => return "generic instance freezes a target";
         when Instance_Legality_Representation_After_Instance_Freezing => return "representation item appears after generic instance freezing";
         when Instance_Legality_Representation_Target_Unresolved => return "representation target is unresolved";
         when Instance_Legality_Representation_Target_Ambiguous => return "representation target is ambiguous";
         when Instance_Legality_Representation_Target_Kind_Mismatch => return "representation target kind is incompatible";
         when Instance_Legality_Representation_Static_Error => return "representation item requires a valid static value";
         when Instance_Legality_Representation_Profile_Error => return "representation stream/profile item is illegal";
         when Instance_Legality_Representation_Operational_Error => return "operational representation item is illegal";
         when Instance_Legality_Assignment_Error => return "generic instance body assignment legality failed";
         when Instance_Legality_Return_Error => return "generic instance body return legality failed";
         when Instance_Legality_Conversion_Access_Aggregate_Error => return "generic instance body expression legality failed";
         when Instance_Legality_Tagged_Derived_Error => return "generic instance tagged/derived legality failed";
         when others => return "generic instance semantic closure is unknown";
      end case;
   end Message_For;

   procedure Append (Model : in out Instance_Legality_Model; Info : Instance_Legality_Info) is
   begin
      Model.Entries.Append (Info);
      if Is_Legal_Status (Info.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      elsif Is_Warning_Status (Info.Status) then
         Model.Warning_Total := Model.Warning_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;

      if Is_Body_Error (Info.Status) then
         Model.Generic_Body_Error_Total := Model.Generic_Body_Error_Total + 1;
      end if;
      if Is_Formal_Package_Error (Info.Status) then
         Model.Formal_Package_Error_Total := Model.Formal_Package_Error_Total + 1;
      end if;
      if Is_Freezing_Error (Info.Status) then
         Model.Freezing_Error_Total := Model.Freezing_Error_Total + 1;
      end if;
      if Is_Representation_Error (Info.Status) then
         Model.Representation_Error_Total := Model.Representation_Error_Total + 1;
      end if;
      if Is_Linked_Error (Info.Status) then
         Model.Linked_Semantic_Error_Total := Model.Linked_Semantic_Error_Total + 1;
      end if;

      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint + 1, Info.Fingerprint + 1);
   end Append;

   procedure Clear (Model : in out Instance_Context_Model) is
   begin
      Model.Entries.Clear;
      Model.Model_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Instance_Context_Model;
      Context : Instance_Context_Info)
   is
      Item : Instance_Context_Info := Context;
   begin
      if Length (Item.Normalized_Instance_Name) = 0 then
         Item.Normalized_Instance_Name := Normalize (Item.Instance_Name);
      end if;
      if Length (Item.Normalized_Target_Name) = 0 then
         Item.Normalized_Target_Name := Normalize (Item.Target_Name);
      end if;
      if Item.Fingerprint = 0 then
         Item.Fingerprint := Context_Fingerprint (Item);
      end if;
      Model.Entries.Append (Item);
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint + 1, Item.Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Instance_Context_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Context_Count;

   function Context_At
     (Model : Instance_Context_Model;
      Index : Positive) return Instance_Context_Info is
   begin
      return Model.Entries.Element (Index);
   end Context_At;

   function Fingerprint (Model : Instance_Context_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Instance_For_Node
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Node      : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Generic_Contracts.Generic_Instance_Info
   is
      use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Empty : Editor.Ada_Generic_Contracts.Generic_Instance_Info;
   begin
      if Node = Editor.Ada_Syntax_Tree.No_Node then
         return Empty;
      end if;

      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
         begin
            if Instance.Node = Node then
               return Instance;
            end if;
         end;
      end loop;

      return Empty;
   end Instance_For_Node;

   function Instance_For_Id
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Id        : Editor.Ada_Generic_Contracts.Generic_Instance_Id)
      return Editor.Ada_Generic_Contracts.Generic_Instance_Info
   is
   begin
      if Id = Editor.Ada_Generic_Contracts.No_Generic_Instance then
         return (others => <>);
      end if;

      return Editor.Ada_Generic_Contracts.Instance (Contracts, Id);
   end Instance_For_Id;

   function Formal_For_Id
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Id        : Editor.Ada_Generic_Contracts.Generic_Formal_Id)
      return Editor.Ada_Generic_Contracts.Generic_Formal_Info
   is
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
   begin
      if Id = Editor.Ada_Generic_Contracts.No_Generic_Formal then
         return (others => <>);
      end if;

      return Editor.Ada_Generic_Contracts.Formal (Contracts, Id);
   end Formal_For_Id;

   function Target_Freezable
     (Freezing : FR.Freezing_Model;
      Target   : FR.Freezable_Id) return FR.Freezable_Info is
   begin
      if Target = FR.No_Freezable then
         return (others => <>);
      end if;

      return FR.Freezable_Node (Freezing, Target);
   end Target_Freezable;

   function Build_Contexts_From_Models
     (Contracts       : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Bodies          : GB.Instantiated_Body_Model;
      Formal_Packages : FP.Formal_Package_Substitution_Model;
      Freezing        : FR.Freezing_Model;
      Representation  : RP.Representation_Legality_Model)
      return Instance_Context_Model
   is
      Model : Instance_Context_Model;
      Next  : Instance_Context_Id := No_Instance_Context;

      procedure Add (Context : Instance_Context_Info) is
         Item : Instance_Context_Info := Context;
      begin
         Next := Next + 1;
         Item.Id := Next;
         Add_Context (Model, Item);
      end Add;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Context  : Instance_Context_Info;
         begin
            Context.Kind := Instance_Context_Generic_Instance;
            Context.Node := Instance.Node;
            Context.Instance_Node := Instance.Node;
            Context.Instance := Instance.Id;
            Context.Instance_Name := Instance.Name;
            Context.Target_Name := Instance.Generic_Name;
            Context.Start_Line := Instance.Start_Line;
            Context.End_Line := Instance.End_Line;
            Context.Fingerprint := Instance.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. GB.Substitution_Count (Bodies) loop
         declare
            Substitution : constant GB.Instantiated_Body_Substitution_Info :=
              GB.Substitution_At (Bodies, Index);
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Instance_For_Id (Contracts, Substitution.Instance);
            Context  : Instance_Context_Info;
         begin
            Context.Kind := Instance_Context_Body_Substitution;
            Context.Node := Substitution.Instance_Node;
            Context.Instance_Node := Substitution.Instance_Node;
            Context.Formal_Node := Substitution.Formal_Node;
            Context.Body_Node := Substitution.Body_Node;
            Context.Instance := Substitution.Instance;
            Context.Formal := Substitution.Formal;
            Context.Body_Substitution := Substitution.Id;
            Context.Instance_Name := Instance.Name;
            Context.Formal_Name := Substitution.Formal_Name;
            Context.Target_Name := Substitution.Formal_Name;
            Context.Body_Status := Substitution.Status;
            Context.Start_Line := Substitution.Start_Line;
            Context.End_Line := Substitution.End_Line;
            Context.Fingerprint := Substitution.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. FP.Substitution_Count (Formal_Packages) loop
         declare
            Substitution : constant FP.Formal_Package_Substitution_Info :=
              FP.Substitution_At (Formal_Packages, Index);
            Instance     : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Instance_For_Id (Contracts, Substitution.Instance);
            Formal       : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
              Formal_For_Id (Contracts, Substitution.Formal);
            Context      : Instance_Context_Info;
         begin
            Context.Kind := Instance_Context_Formal_Package_Substitution;
            Context.Node := Substitution.Instance_Node;
            Context.Instance_Node := Substitution.Instance_Node;
            Context.Formal_Node := Substitution.Formal_Node;
            Context.Instance := Substitution.Instance;
            Context.Formal := Substitution.Formal;
            Context.Formal_Package_Substitution := Substitution.Id;
            Context.Instance_Name := Instance.Name;
            Context.Formal_Name := Substitution.Formal_Name;
            Context.Target_Name :=
              (if Length (Substitution.Expected_Generic) > 0
               then Substitution.Expected_Generic
               else Formal.Formal_Package_Generic_Name);
            Context.Formal_Package_Status := Substitution.Status;
            Context.Start_Line := Substitution.Start_Line;
            Context.End_Line := Substitution.End_Line;
            Context.Fingerprint := Substitution.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. FR.Freezable_Count (Freezing) loop
         declare
            Freezable : constant FR.Freezable_Info := FR.Freezable_At (Freezing, Index);
            Instance  : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Instance_For_Node (Contracts, Freezable.First_Freeze_Node);
            Context   : Instance_Context_Info;
         begin
            if Freezable.Cause = FR.Freezing_Cause_Instantiation then
               Context.Kind := Instance_Context_Instance_Freezing;
               Context.Node := Freezable.First_Freeze_Node;
               Context.Instance_Node := Instance.Node;
               Context.Instance := Instance.Id;
               Context.Freezable := Freezable.Id;
               Context.Instance_Name := Instance.Name;
               Context.Target_Name := Freezable.Name;
               Context.Freeze_Status := Freezable.Status;
               Context.Instance_Freezes_Target := Freezable.Status = FR.Freezing_Frozen;
               Context.Start_Line := Freezable.First_Freeze_Line;
               Context.End_Line := Freezable.First_Freeze_Line;
               Context.Fingerprint := Freezable.Fingerprint;
               Add (Context);
            end if;
         end;
      end loop;

      for Index in 1 .. RP.Check_Count (Representation) loop
         declare
            Check     : constant RP.Representation_Legality_Info :=
              RP.Check_At (Representation, Index);
            Freezable : constant FR.Freezable_Info :=
              Target_Freezable (Freezing, Check.Target);
            Instance  : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Instance_For_Node (Contracts, Freezable.First_Freeze_Node);
            Context   : Instance_Context_Info;
         begin
            if Freezable.Cause = FR.Freezing_Cause_Instantiation then
               Context.Kind := Instance_Context_Representation_Item;
               Context.Node := Check.Clause_Node;
               Context.Instance_Node := Instance.Node;
               Context.Representation_Node := Check.Clause_Node;
               Context.Instance := Instance.Id;
               Context.Freezable := Check.Target;
               Context.Instance_Name := Instance.Name;
               Context.Target_Name := Check.Target_Name;
               Context.Freeze_Status := Freezable.Status;
               Context.Representation_Status := Check.Status;
               Context.Representation_After_Instance_Freezing :=
                 Check.Status = RP.Representation_Legality_After_Freezing
                 or else Check.Freeze_Status = FR.Representation_After_Freezing;
               Context.Start_Line := Check.Source_Line;
               Context.End_Line := Check.Source_Line;
               Context.Fingerprint := Check.Fingerprint;
               Add (Context);
            end if;
         end;
      end loop;

      return Model;
   end Build_Contexts_From_Models;

   function Classify
     (Context     : Instance_Context_Info;
      Assignments : AL.Assignment_Legality_Model;
      Returns     : RL.Return_Legality_Model;
      Expressions : EL.Semantic_Legality_Model;
      Tagged_Model      : TD.Tagged_Legality_Model) return Instance_Legality_Status is
   begin
      if Assignment_Error (Assignments, Context.Linked_Assignment) then
         return Instance_Legality_Assignment_Error;
      elsif Return_Error (Returns, Context.Linked_Return) then
         return Instance_Legality_Return_Error;
      elsif Expression_Error (Expressions, Context.Linked_Expression) then
         return Instance_Legality_Conversion_Access_Aggregate_Error;
      elsif Tagged_Error (Tagged_Model, Context.Linked_Tagged) then
         return Instance_Legality_Tagged_Derived_Error;
      elsif Context.Representation_After_Instance_Freezing then
         return Instance_Legality_Representation_After_Instance_Freezing;
      end if;

      case Context.Kind is
         when Instance_Context_Generic_Instance =>
            return Instance_Legality_Legal_Instance;
         when Instance_Context_Body_Substitution =>
            return Body_Status_To_Instance (Context.Body_Status);
         when Instance_Context_Formal_Package_Substitution =>
            return Formal_Package_Status_To_Instance (Context.Formal_Package_Status);
         when Instance_Context_Instance_Freezing =>
            if Context.Instance_Freezes_Target then
               return Instance_Legality_Instance_Freezes_Target;
            elsif Context.Freeze_Status = FR.Freezing_Target_Unresolved then
               return Instance_Legality_Representation_Target_Unresolved;
            elsif Context.Freeze_Status = FR.Freezing_Target_Ambiguous then
               return Instance_Legality_Representation_Target_Ambiguous;
            else
               return Instance_Legality_Legal_Instance_Freezing;
            end if;
         when Instance_Context_Representation_Item =>
            return Representation_Status_To_Instance (Context.Representation_Status);
         when Instance_Context_Instance_Body_Expression =>
            return Instance_Legality_Legal_Instance;
         when Instance_Context_Tagged_Derived_Effect =>
            return Instance_Legality_Legal_Instance;
         when Instance_Context_Unknown =>
            return Instance_Legality_Unknown;
      end case;
   end Classify;

   function Build
     (Contexts      : Instance_Context_Model;
      Bodies        : GB.Instantiated_Body_Model;
      Formal_Packages : FP.Formal_Package_Substitution_Model;
      Freezing      : FR.Freezing_Model;
      Representation : RP.Representation_Legality_Model;
      Assignments   : AL.Assignment_Legality_Model;
      Returns       : RL.Return_Legality_Model;
      Expressions   : EL.Semantic_Legality_Model;
      Tagged_Model        : TD.Tagged_Legality_Model)
      return Instance_Legality_Model
   is
      pragma Unreferenced (Bodies, Formal_Packages, Freezing, Representation);
      Model : Instance_Legality_Model;
   begin
      for Index in 1 .. Context_Count (Contexts) loop
         declare
            Context : constant Instance_Context_Info := Context_At (Contexts, Index);
            Info    : Instance_Legality_Info;
         begin
            Info.Id := Instance_Legality_Id (Index);
            Info.Context := Context.Id;
            Info.Kind := Context.Kind;
            Info.Node := Context.Node;
            Info.Instance_Node := Context.Instance_Node;
            Info.Formal_Node := Context.Formal_Node;
            Info.Body_Node := Context.Body_Node;
            Info.Representation_Node := Context.Representation_Node;
            Info.Instance := Context.Instance;
            Info.Formal := Context.Formal;
            Info.Status := Classify (Context, Assignments, Returns, Expressions, Tagged_Model);
            Info.Message := To_Unbounded_String (Message_For (Info.Status));
            Info.Detail := To_Unbounded_String ("generic instance/freezing/representation semantic closure");
            Info.Normalized_Instance_Name := Context.Normalized_Instance_Name;
            Info.Normalized_Target_Name := Context.Normalized_Target_Name;
            Info.Source_Fingerprint := Context.Fingerprint;
            Info.Fingerprint := Legality_Fingerprint (Info);
            Append (Model, Info);
         end;
      end loop;

      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint + 1, Contexts.Model_Fingerprint + 1);
      return Model;
   end Build;

   function Legality_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Legality_Count;

   function Legality_At
     (Model : Instance_Legality_Model;
      Index : Positive) return Instance_Legality_Info is
   begin
      return Model.Entries.Element (Index);
   end Legality_At;

   function First_For_Context
     (Model   : Instance_Legality_Model;
      Context : Instance_Context_Id) return Instance_Legality_Info is
   begin
      for Info of Model.Entries loop
         if Info.Context = Context then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Instance
     (Model    : Instance_Legality_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id) return Instance_Legality_Info is
   begin
      for Info of Model.Entries loop
         if Info.Instance = Instance then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Instance;

   function First_For_Node
     (Model : Instance_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Instance_Legality_Info is
   begin
      for Info of Model.Entries loop
         if Info.Node = Node or else Info.Instance_Node = Node
           or else Info.Formal_Node = Node or else Info.Body_Node = Node
           or else Info.Representation_Node = Node
         then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Instance_Legality_Model;
      Status : Instance_Legality_Status) return Instance_Result_Set is
      Results : Instance_Result_Set;
   begin
      for Info of Model.Entries loop
         if Info.Status = Status then
            Results.Entries.Append (Info);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Instance_Legality_Model;
      Kind  : Instance_Context_Kind) return Instance_Result_Set is
      Results : Instance_Result_Set;
   begin
      for Info of Model.Entries loop
         if Info.Kind = Kind then
            Results.Entries.Append (Info);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Target
     (Model : Instance_Legality_Model;
      Name  : Unbounded_String) return Instance_Result_Set is
      Results : Instance_Result_Set;
      Needle  : constant Unbounded_String := Normalize (Name);
   begin
      for Info of Model.Entries loop
         if Info.Normalized_Target_Name = Needle then
            Results.Entries.Append (Info);
         end if;
      end loop;
      return Results;
   end Rows_For_Target;

   function Result_Count (Results : Instance_Result_Set) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Result_Count;

   function Result_At
     (Results : Instance_Result_Set;
      Index   : Positive) return Instance_Legality_Info is
   begin
      return Results.Entries.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Instance_Legality_Model;
      Status : Instance_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Entries loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Instance_Legality_Model;
      Kind  : Instance_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Entries loop
         if Info.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Generic_Body_Error_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Generic_Body_Error_Total;
   end Generic_Body_Error_Count;

   function Formal_Package_Error_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Formal_Package_Error_Total;
   end Formal_Package_Error_Count;

   function Freezing_Error_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Freezing_Error_Total;
   end Freezing_Error_Count;

   function Representation_Error_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Representation_Error_Total;
   end Representation_Error_Count;

   function Linked_Semantic_Error_Count (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Linked_Semantic_Error_Total;
   end Linked_Semantic_Error_Count;

   function Fingerprint (Model : Instance_Legality_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
