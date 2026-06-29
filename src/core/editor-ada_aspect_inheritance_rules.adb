with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Aspect_Inheritance_Rules is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Normalize (Text : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String (Ada.Characters.Handling.To_Lower (To_String (Text)));
   end Normalize;

   function Is_Inheritable_Property
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean is
   begin
      return Kind in
        Editor.Ada_Language_Model.Representation_Pack_Clause |
        Editor.Ada_Language_Model.Representation_Atomic_Clause |
        Editor.Ada_Language_Model.Representation_Volatile_Clause |
        Editor.Ada_Language_Model.Representation_Independent_Clause |
        Editor.Ada_Language_Model.Representation_Atomic_Components_Clause |
        Editor.Ada_Language_Model.Representation_Volatile_Components_Clause |
        Editor.Ada_Language_Model.Representation_Independent_Components_Clause |
        Editor.Ada_Language_Model.Representation_Suppress_Initialization_Clause |
        Editor.Ada_Language_Model.Representation_Unchecked_Union_Clause |
        Editor.Ada_Language_Model.Representation_Discard_Names_Clause |
        Editor.Ada_Language_Model.Representation_Volatile_Full_Access_Clause |
        Editor.Ada_Language_Model.Representation_Atomic_Always_Lock_Free_Clause |
        Editor.Ada_Language_Model.Representation_Convention_Clause |
        Editor.Ada_Language_Model.Representation_Size_Clause |
        Editor.Ada_Language_Model.Representation_Object_Size_Clause |
        Editor.Ada_Language_Model.Representation_Value_Size_Clause |
        Editor.Ada_Language_Model.Representation_Alignment_Clause;
   end Is_Inheritable_Property;

   function Same_Value
     (Left, Right : Unbounded_String) return Boolean is
   begin
      return Normalize (Left) = Normalize (Right);
   end Same_Value;

   function Clause_Target_Type_Name (Target : Unbounded_String) return Unbounded_String is
      Text : constant String := To_String (Target);
   begin
      for I in Text'Range loop
         if Text (I) = Character'Val (39) then
            if I > Text'First then
               return Normalize (To_Unbounded_String (Text (Text'First .. I - 1)));
            else
               return Null_Unbounded_String;
            end if;
         end if;
      end loop;
      return Normalize (Target);
   end Clause_Target_Type_Name;

   function Type_For_Target
     (Types  : Editor.Ada_Type_Graph.Type_Model;
      Target : Unbounded_String) return Editor.Ada_Type_Graph.Type_Info is
      Wanted : constant Unbounded_String := Normalize (Target);
   begin
      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if Info.Normalized_Name = Wanted then
               return Info;
            end if;
         end;
      end loop;

      return (others => <>);
   end Type_For_Target;

   function Clause_For
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Type_Name : Unbounded_String;
      Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind)
      return Editor.Ada_Representation_Legality.Representation_Legality_Info is
      Wanted : constant Unbounded_String := Normalize (Type_Name);
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Check : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Is_Inheritable_Property (Check.Clause_Kind)
              and then Check.Clause_Kind = Kind
              and then Clause_Target_Type_Name (Check.Target_Name) = Wanted
            then
               return Check;
            end if;
         end;
      end loop;

      return (others => <>);
   end Clause_For;

   procedure Add_Rule
     (Model : in out Aspect_Inheritance_Model;
      Info  : in out Aspect_Inheritance_Info) is
   begin
      Info.Fingerprint :=
        Mix (Natural (Info.Target_Type),
             Mix (Natural (Info.Ancestor_Type),
                  Mix (Natural (Info.Clause_Node),
                       Mix (Natural (Info.Ancestor_Clause),
                            Mix (Editor.Ada_Language_Model.Representation_Clause_Kind'Pos (Info.Property_Kind),
                                 Aspect_Inheritance_Status'Pos (Info.Status))))));

      case Info.Status is
         when Aspect_Inheritance_Inherited =>
            Model.Inherited_Total := Model.Inherited_Total + 1;
         when Aspect_Inheritance_Explicit_Override |
              Aspect_Inheritance_Private_Full_View_Override =>
            Model.Override_Total := Model.Override_Total + 1;
         when Aspect_Inheritance_Explicit_Conflict =>
            Model.Conflict_Total := Model.Conflict_Total + 1;
         when Aspect_Inheritance_Private_Partial_View =>
            Model.Private_View_Total := Model.Private_View_Total + 1;
         when Aspect_Inheritance_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
         when Aspect_Inheritance_Not_Inherited =>
            null;
      end case;

      Model.Rules.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Add_Rule;

   procedure Clear (Model : in out Aspect_Inheritance_Model) is
   begin
      Model.Rules.Clear;
      Model.Inherited_Total := 0;
      Model.Override_Total := 0;
      Model.Conflict_Total := 0;
      Model.Private_View_Total := 0;
      Model.Unknown_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Types    : Editor.Ada_Type_Graph.Type_Model) return Aspect_Inheritance_Model is
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Type_Graph.Type_Category;
      use type Editor.Ada_Type_Graph.Type_View_Status;
      Result : Aspect_Inheritance_Model;
   begin
      for Type_Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Target : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Type_Index);
         begin
            if Target.Base_Type /= Editor.Ada_Type_Graph.No_Type
              or else Length (Target.Normalized_Base) > 0
            then
               declare
                  Ancestor : constant Editor.Ada_Type_Graph.Type_Info :=
                    (if Target.Base_Type /= Editor.Ada_Type_Graph.No_Type
                     then Editor.Ada_Type_Graph.Type_Node (Types, Target.Base_Type)
                     else Type_For_Target (Types, Target.Normalized_Base));
               begin
                  if Ancestor.Id /= Editor.Ada_Type_Graph.No_Type then
                     for Check_Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
                        declare
                           Ancestor_Check : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
                             Editor.Ada_Representation_Legality.Check_At (Legality, Check_Index);
                        begin
                           if Is_Inheritable_Property (Ancestor_Check.Clause_Kind)
                             and then Clause_Target_Type_Name (Ancestor_Check.Target_Name) =
                               Ancestor.Normalized_Name
                           then
                              declare
                                 Explicit : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
                                   Clause_For (Legality, Target.Normalized_Name, Ancestor_Check.Clause_Kind);
                                 Rule : Aspect_Inheritance_Info;
                              begin
                                 Rule.Target_Type := Target.Id;
                                 Rule.Ancestor_Type := Ancestor.Id;
                                 Rule.Ancestor_Clause := Ancestor_Check.Clause_Node;
                                 Rule.Target_Name := Target.Name;
                                 Rule.Ancestor_Name := Ancestor.Name;
                                 Rule.Property_Kind := Ancestor_Check.Clause_Kind;
                                 Rule.Inherited_Value := Ancestor_Check.Item_Text;
                                 Rule.Source_Line := Target.Start_Line;

                                 if Explicit.Clause_Node = Editor.Ada_Syntax_Tree.No_Node then
                                    if Target.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Partial then
                                       Rule.Status := Aspect_Inheritance_Private_Partial_View;
                                    else
                                       Rule.Status := Aspect_Inheritance_Inherited;
                                    end if;
                                 else
                                    Rule.Clause_Node := Explicit.Clause_Node;
                                    Rule.Explicit_Source := Explicit.Source_Form;
                                    Rule.Explicit_Value := Explicit.Item_Text;
                                    Rule.Source_Line := Explicit.Source_Line;

                                    if Target.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Full then
                                       Rule.Status := Aspect_Inheritance_Private_Full_View_Override;
                                    elsif Same_Value (Explicit.Item_Text, Ancestor_Check.Item_Text) then
                                       Rule.Status := Aspect_Inheritance_Explicit_Override;
                                    else
                                       Rule.Status := Aspect_Inheritance_Explicit_Conflict;
                                    end if;
                                 end if;

                                 Add_Rule (Result, Rule);
                              end;
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end if;
         end;
      end loop;

      return Result;
   end Build;

   function Rule_Count (Model : Aspect_Inheritance_Model) return Natural is
   begin
      return Natural (Model.Rules.Length);
   end Rule_Count;

   function Rule_At
     (Model : Aspect_Inheritance_Model;
      Index : Positive) return Aspect_Inheritance_Info is
   begin
      return Model.Rules (Index);
   end Rule_At;

   function Inherited_Count (Model : Aspect_Inheritance_Model) return Natural is
   begin
      return Model.Inherited_Total;
   end Inherited_Count;

   function Override_Count (Model : Aspect_Inheritance_Model) return Natural is
   begin
      return Model.Override_Total;
   end Override_Count;

   function Conflict_Count (Model : Aspect_Inheritance_Model) return Natural is
   begin
      return Model.Conflict_Total;
   end Conflict_Count;

   function Private_View_Count (Model : Aspect_Inheritance_Model) return Natural is
   begin
      return Model.Private_View_Total;
   end Private_View_Count;

   function Unknown_Count (Model : Aspect_Inheritance_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Fingerprint (Model : Aspect_Inheritance_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Aspect_Inheritance_Rules;
