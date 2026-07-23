with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Syntax_Tree;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers is

   use Editor.Ada_Language_Model;
   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
   use Editor.Ada_Syntax_Tree;

   function Pragma_Metadata_Argument_Count
     (Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural is
   begin
      return Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument_Count
        (To_String (Node.Label));
   end Pragma_Metadata_Argument_Count;

   function Pragma_Metadata_Named_Argument_Count
     (Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural is
      Text  : constant String := To_String (Node.Label);
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument_Count (Text) loop
         if Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument_Name
             (Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Argument (Text, I)) /= ""
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Pragma_Metadata_Named_Argument_Count;

   function Pragma_Metadata_Target
     (Node : Editor.Ada_Syntax_Tree.Node_Info) return String is
   begin
      return Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Target
        (To_String (Node.Label));
   end Pragma_Metadata_Target;

   function Pragma_Placement_For_Node
     (Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Node  : Editor.Ada_Syntax_Tree.Node_Info;
      Owner : Symbol_Id)
      return Pragma_Placement_Kind
   is
      Name : constant String :=
        Lower (Editor.Ada_Declaration_Parser.Pragma_Helpers.Pragma_Metadata_Name
                 (To_String (Node.Label)));
   begin
      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Pragma_Statement then
         if Has_Ancestor_Kind (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Statement_Alternative)
           or else Has_Ancestor_Kind (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Select_Alternative)
           or else Has_Ancestor_Kind (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_When_Alternative)
         then
            return Pragma_Placement_Alternative;
         elsif Name = "inline"
           or else Name = "inline_always"
           or else Name = "no_inline"
           or else Name = "no_return"
           or else Name = "atomic"
           or else Name = "volatile"
           or else Name = "independent"
           or else Name = "import"
           or else Name = "export"
           or else Name = "convention"
         then
            return Pragma_Placement_Declaration;
         else
            return Pragma_Placement_Statement;
         end if;
      elsif Owner = No_Symbol then
         return Pragma_Placement_Configuration;
      else
         return Pragma_Placement_Declaration;
      end if;
   end Pragma_Placement_For_Node;

   function Syntax_Node_Symbol_Kind
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      N    : Editor.Ada_Syntax_Tree.Node_Info)
      return Symbol_Kind
   is
      L : constant String := Lower (To_String (N.Label));
   begin
      case N.Kind is
         when Editor.Ada_Syntax_Tree.Node_Package_Declaration =>
            if Has_Token (L, "new") then
               return Symbol_Instantiation;
            elsif Has_Direct_Generic_Parent (Tree, N) then
               return Symbol_Generic_Package;
            else
               return Symbol_Package;
            end if;
         when Editor.Ada_Syntax_Tree.Node_Package_Body =>
            return Symbol_Package_Body;
         when Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration =>
            return Symbol_Generic_Formal_Subprogram;
         when Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
            | Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Body
            | Editor.Ada_Syntax_Tree.Node_Body_Stub =>
            if Has_Direct_Generic_Parent (Tree, N) then
               return Symbol_Generic_Subprogram;
            end if;
            if Starts_With_Word (L, "function") then
               declare
                  Name : constant String := First_Child_Label (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Name);
               begin
                  if Name'Length > 0 and then Name (Name'First) = '"' then
                     return Symbol_Operator_Function;
                  end if;
               end;
               return Symbol_Function;
            else
               return Symbol_Procedure;
            end if;
         when Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration =>
            return Symbol_Generic_Formal_Type;
         when Editor.Ada_Syntax_Tree.Node_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Incomplete_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration =>
            if Has_Token (L, "record") or else Has_Child_Kind (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Variant_Part) then
               return Symbol_Record_Type;
            else
               return Symbol_Type;
            end if;
         when Editor.Ada_Syntax_Tree.Node_Subtype_Declaration =>
            return Symbol_Subtype;
         when Editor.Ada_Syntax_Tree.Node_Component_Declaration =>
            return Symbol_Record_Component;
         when Editor.Ada_Syntax_Tree.Node_Discriminant_Specification =>
            return Symbol_Discriminant;
         when Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration =>
            return Symbol_Enumeration_Literal;
         when Editor.Ada_Syntax_Tree.Node_Constant_Declaration | Editor.Ada_Syntax_Tree.Node_Deferred_Constant_Declaration =>
            return Symbol_Constant;
         when Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration =>
            return Symbol_Generic_Formal_Object;
         when Editor.Ada_Syntax_Tree.Node_Number_Declaration | Editor.Ada_Syntax_Tree.Node_Object_Declaration =>
            return Symbol_Object;
         when Editor.Ada_Syntax_Tree.Node_Exception_Declaration =>
            return Symbol_Exception;
         when Editor.Ada_Syntax_Tree.Node_Formal_Package_Declaration =>
            return Symbol_Generic_Formal_Package;
         when Editor.Ada_Syntax_Tree.Node_Generic_Declaration =>
            if Starts_With_Word (L, "package") then
               return Symbol_Generic_Package;
            else
               return Symbol_Generic_Subprogram;
            end if;
         when Editor.Ada_Syntax_Tree.Node_Rename_Declaration =>
            return Symbol_Rename;
         when Editor.Ada_Syntax_Tree.Node_Instantiation =>
            return Symbol_Instantiation;
         when Editor.Ada_Syntax_Tree.Node_Separate_Body =>
            return Symbol_Separate_Body;
         when Editor.Ada_Syntax_Tree.Node_Task_Declaration | Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration | Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration | Editor.Ada_Syntax_Tree.Node_Task_Body =>
            return Symbol_Task;
         when Editor.Ada_Syntax_Tree.Node_Protected_Declaration | Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration | Editor.Ada_Syntax_Tree.Node_Single_Protected_Declaration | Editor.Ada_Syntax_Tree.Node_Protected_Body =>
            return Symbol_Protected;
         when Editor.Ada_Syntax_Tree.Node_Entry_Declaration | Editor.Ada_Syntax_Tree.Node_Entry_Body | Editor.Ada_Syntax_Tree.Node_Entry_Body_Stub =>
            return Symbol_Entry;
         when Editor.Ada_Syntax_Tree.Node_Choice_Parameter_Specification =>
            return Symbol_Object;
         when others =>
            return Symbol_Unknown;
      end case;
   end Syntax_Node_Symbol_Kind;

   function Syntax_Node_Flags
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      N    : Editor.Ada_Syntax_Tree.Node_Info)
      return Declaration_Flags
   is
      Flags : Declaration_Flags := (others => False);
   begin
      case N.Kind is
         when Editor.Ada_Syntax_Tree.Node_Package_Body
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Body
            | Editor.Ada_Syntax_Tree.Node_Task_Body
            | Editor.Ada_Syntax_Tree.Node_Protected_Body
            | Editor.Ada_Syntax_Tree.Node_Entry_Body =>
            Flags.Is_Body := True;
         when others =>
            null;
      end case;

      case N.Kind is
         when Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration =>
            Flags.Is_Abstract := True;
         when Editor.Ada_Syntax_Tree.Node_Generic_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Package_Declaration =>
            Flags.Is_Generic := True;
         when Editor.Ada_Syntax_Tree.Node_Rename_Declaration =>
            Flags.Is_Rename := True;
         when Editor.Ada_Syntax_Tree.Node_Instantiation =>
            Flags.Is_Instantiation := True;
         when Editor.Ada_Syntax_Tree.Node_Package_Declaration =>
            if Has_Token (Lower (To_String (N.Label)), "new") then
               Flags.Is_Instantiation := True;
               Flags.Has_Generic_Actual_Part_Metadata :=
                 Has_Child_Kind (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Generic_Actual_Part);
            end if;
         when Editor.Ada_Syntax_Tree.Node_Separate_Body =>
            Flags.Is_Separate := True;
         when Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration =>
            Flags.Has_Task_Type_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration =>
            Flags.Has_Protected_Type_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Incomplete_Type_Declaration =>
            Flags.Has_Incomplete_Type_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration =>
            Flags.Has_Private_Extension_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Number_Declaration =>
            Flags.Has_Named_Number_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Deferred_Constant_Declaration =>
            Flags.Has_Deferred_Constant_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration =>
            Flags.Has_Null_Subprogram_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration =>
            Flags.Has_Expression_Function_Metadata := True;
         when Editor.Ada_Syntax_Tree.Node_Body_Stub | Editor.Ada_Syntax_Tree.Node_Entry_Body_Stub =>
            Flags.Has_Body_Stub_Metadata := True;
            Flags.Is_Separate := True;
         when others =>
            null;
      end case;

      if Has_Direct_Generic_Parent (Tree, N)
        and then N.Kind in Editor.Ada_Syntax_Tree.Node_Package_Declaration
                           | Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
                           | Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
                           | Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
                           | Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration
      then
         Flags.Is_Generic := True;
      end if;

      if Has_Child_Kind (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Aspect_Specification) then
         Flags.Has_Aspect_Specification := True;
      end if;
      if Has_Child_Kind (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Generic_Actual_Part) then
         Flags.Has_Generic_Actual_Part_Metadata := True;
      end if;
      if Has_Child_Kind (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Representation_Clause)
        or else Has_Child_Kind (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Representation_Component_Clause)
      then
         Flags.Has_Representation_Clause := True;
      end if;
      if Has_Child_Kind (Tree, N.Id, Editor.Ada_Syntax_Tree.Node_Variant_Part) then
         Flags.Has_Variant_Record_Metadata := True;
      end if;
      return Flags;
   end Syntax_Node_Flags;

   function Qualified_Name
     (Analysis  : Editor.Ada_Language_Model.Analysis_Result;
      Symbol    : Editor.Ada_Language_Model.Symbol_Info;
      Remaining : Natural;
      Truncated : in out Boolean) return String
   is
      Local : constant String := To_String (Symbol.Name);
      Prefix : Unbounded_String;
   begin
      if Symbol.Parent_Symbol = No_Symbol then
         return Local;
      end if;

      if Remaining = 0
        or else Natural (Symbol.Parent_Symbol) > Symbol_Count (Analysis)
      then
         Truncated := True;
         return Local;
      end if;

      declare
         Parent : constant Symbol_Info := Editor.Ada_Language_Model.Symbol (Analysis, Symbol.Parent_Symbol);
      begin
         if not Is_Declaration_Owner (Parent.Kind) then
            Truncated := True;
            return Local;
         end if;

         Prefix := To_Unbounded_String
           (Qualified_Name (Analysis, Parent, Remaining - 1, Truncated));
      end;

      if Truncated or else Length (Prefix) = 0 then
         return Local;
      end if;
      return To_String (Prefix) & "." & Local;
   exception
      when others =>
         Truncated := True;
         return Local;
   end Qualified_Name;

   function Qualified_Name
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String
   is
      Truncated : Boolean := False;
   begin
      return Qualified_Name (Analysis, Symbol, Symbol_Count (Analysis), Truncated);
   end Qualified_Name;

   function Kind_Compatible
     (Existing : Symbol_Kind;
      Wanted   : Symbol_Kind) return Boolean is
   begin
      return Existing = Wanted
        or else Wanted = Symbol_Unknown
        or else Existing = Symbol_Unknown
        or else (Existing = Symbol_Generic_Package and then Wanted = Symbol_Package)
        or else (Existing = Symbol_Package and then Wanted = Symbol_Generic_Package)
        or else (Is_Subprogram (Existing) and then Is_Subprogram (Wanted))
        or else (Is_Type_Like (Existing) and then Is_Type_Like (Wanted));
   end Kind_Compatible;

   function Same_Line_Projection_Compatible
     (Existing : Symbol_Kind;
      Wanted   : Symbol_Kind) return Boolean is
   begin
      return Kind_Compatible (Existing, Wanted)
        or else (Existing in Symbol_Object | Symbol_Constant
                 and then Wanted in Symbol_Object | Symbol_Constant)
        or else (Wanted = Symbol_Object
                 and then Existing in Symbol_Discriminant
                                   | Symbol_Record_Component
                                   | Symbol_Generic_Formal_Object
                                   | Symbol_Exception)
        or else (Wanted = Symbol_Rename
                 and then Existing in Symbol_Object
                                   | Symbol_Constant
                                   | Symbol_Exception
                                   | Symbol_Package
                                   | Symbol_Package_Body
                                   | Symbol_Procedure
                                   | Symbol_Function
                                   | Symbol_Operator_Function
                                   | Symbol_Generic_Package
                                   | Symbol_Generic_Subprogram);
   end Same_Line_Projection_Compatible;

   function Preferred_Merged_Kind
     (Existing : Symbol_Kind;
      Wanted   : Symbol_Kind) return Symbol_Kind is
   begin
      if Wanted = Symbol_Unknown then
         return Existing;
      elsif Existing = Symbol_Unknown or else Existing = Wanted then
         return Wanted;
      elsif Existing = Symbol_Generic_Package and then Wanted = Symbol_Package then
         return Existing;
      elsif Wanted = Symbol_Generic_Package and then Existing = Symbol_Package then
         return Wanted;
      elsif Existing = Symbol_Separate_Body and then Is_Subprogram (Wanted) then
         return Existing;
      elsif Wanted = Symbol_Separate_Body and then Is_Subprogram (Existing) then
         return Wanted;
      elsif Existing = Symbol_Generic_Subprogram and then Is_Subprogram (Wanted) then
         return Existing;
      elsif Wanted = Symbol_Generic_Subprogram and then Is_Subprogram (Existing) then
         return Wanted;
      elsif Existing = Symbol_Generic_Formal_Type and then Is_Type_Like (Wanted) then
         return Existing;
      elsif Wanted = Symbol_Generic_Formal_Type and then Is_Type_Like (Existing) then
         return Wanted;
      elsif Existing = Symbol_Record_Type and then Wanted = Symbol_Type then
         return Existing;
      elsif Wanted = Symbol_Record_Type and then Existing = Symbol_Type then
         return Wanted;
      elsif Existing in Symbol_Discriminant | Symbol_Record_Component | Symbol_Generic_Formal_Object | Symbol_Exception
        and then Wanted = Symbol_Object
      then
         return Existing;
      elsif Existing = Symbol_Object
        and then Wanted in Symbol_Discriminant | Symbol_Record_Component | Symbol_Generic_Formal_Object | Symbol_Exception
      then
         return Wanted;
      elsif Existing in Symbol_Object | Symbol_Constant
        and then Wanted in Symbol_Object | Symbol_Constant
      then
         return Existing;
      elsif Wanted = Symbol_Rename
        and then Existing in Symbol_Object
                          | Symbol_Constant
                          | Symbol_Exception
                          | Symbol_Package
                          | Symbol_Package_Body
                          | Symbol_Procedure
                          | Symbol_Function
                          | Symbol_Operator_Function
                          | Symbol_Generic_Package
                          | Symbol_Generic_Subprogram
      then
         return Existing;
      elsif Existing = Symbol_Operator_Function
        and then (Wanted = Symbol_Function
                  or else Wanted = Symbol_Procedure
                  or else Wanted = Symbol_Generic_Subprogram)
      then
         return Existing;
      elsif Wanted = Symbol_Operator_Function
        and then (Existing = Symbol_Function
                  or else Existing = Symbol_Procedure
                  or else Existing = Symbol_Generic_Subprogram)
      then
         return Wanted;
      else
         return Wanted;
      end if;
   end Preferred_Merged_Kind;

   function Clean_Projected_Declaration_Name (Name : String) return String is
      T : constant String := Trim (Name);
      L : constant String := Lower (T);

      function Strip_Leading_Body return String is
         Start : Natural := T'First + 4;
      begin
         if not Starts_With_Word (L, "body") then
            return T;
         end if;

         while Start <= T'Last
           and then (T (Start) = ' '
                     or else T (Start) = Ada.Characters.Latin_1.HT)
         loop
            Start := Start + 1;
         end loop;

         if Start <= T'Last then
            return Trim (T (Start .. T'Last));
         else
            return "";
         end if;
      end Strip_Leading_Body;
   begin
      if T'Length = 0 then
         return "";
      elsif T (T'First) = '(' then
         return "";
      elsif T (T'First) = '"' or else T (T'First) = Character'Val (16#27#) then
         return T;
      elsif Starts_With_Word (L, "body") then
         return Clean_Projected_Declaration_Name (Strip_Leading_Body);
      elsif Ends_With (L, " is") and then T'Length > 3 then
         return Clean_Projected_Declaration_Name
           (Trim (T (T'First .. T'Last - 3)));
      end if;

      for I in T'Range loop
         if T (I) = ' ' or else T (I) = Ada.Characters.Latin_1.HT then
            if I = T'First then
               return "";
            else
               declare
                  Candidate : constant String := T (T'First .. I - 1);
               begin
                  if Editor.Ada_Declaration_Parser.Source_Awareness.Is_Invalid_Compact_Owner_Name
                       (Candidate)
                  then
                     return "";
                  else
                     return Candidate;
                  end if;
               end;
            end if;
         end if;
      end loop;

      if Editor.Ada_Declaration_Parser.Source_Awareness.Is_Invalid_Compact_Owner_Name
           (T)
      then
         return "";
      else
         return T;
      end if;
   end Clean_Projected_Declaration_Name;

   function Target_Name_Matches
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info;
      Name     : String) return Boolean
   is
      Wanted : constant String := Normalize_Name (Name);
      Symbol_Name : constant String := To_String (Symbol.Normalized_Name);
      Full_Name : constant String := Normalize_Name (Qualified_Name (Analysis, Symbol));
   begin
      if Editor.Ada_Declaration_Parser.Legality_Profile_Helpers.Last_Selected_Name_Part (Name) /= Name then
         return Symbol_Name = Wanted
           or else Full_Name = Wanted
           or else Ends_With (Full_Name, "." & Wanted);
      end if;

      return Symbol_Name = Wanted
        or else Normalize_Name
          (Editor.Ada_Declaration_Parser.Legality_Profile_Helpers.Last_Selected_Name_Part
             (To_String (Symbol.Name))) = Wanted;
   end Target_Name_Matches;

   function Direct_Name_Matches
     (Symbol : Editor.Ada_Language_Model.Symbol_Info;
      Name   : String) return Boolean
   is
      Wanted : constant String := Normalize_Name (Name);
   begin
      return To_String (Symbol.Normalized_Name) = Wanted;
   end Direct_Name_Matches;

   function Find_Existing
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String;
      Kind     : Editor.Ada_Language_Model.Symbol_Kind;
      Line     : Positive) return Editor.Ada_Language_Model.Symbol_Id
   is
   begin
      if Name'Length = 0 then
         return No_Symbol;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if Direct_Name_Matches (S, Name)
              and then S.Declaration_Line = Line
              and then Same_Line_Projection_Compatible (S.Kind, Kind)
            then
               return S.Id;
            end if;
         end;
      end loop;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if Direct_Name_Matches (S, Name)
              and then Kind_Compatible (S.Kind, Kind)
            then
               return S.Id;
            end if;
         end;
      end loop;

      return No_Symbol;
   end Find_Existing;

   function Parent_Selected_Name
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Symbol   : Editor.Ada_Language_Model.Symbol_Info) return String is
   begin
      if Symbol.Parent_Symbol = No_Symbol then
         return "";
      elsif Natural (Symbol.Parent_Symbol) > Symbol_Count (Analysis) then
         return "";
      else
         return Qualified_Name (Analysis, Symbol_At (Analysis, Positive (Symbol.Parent_Symbol)));
      end if;
   end Parent_Selected_Name;

   function Find_Metadata_Target_Direct
     (Analysis    : Editor.Ada_Language_Model.Analysis_Result;
      Target_Name : String) return Editor.Ada_Language_Model.Symbol_Id is
      Clean : constant String := Editor.Ada_Declaration_Parser.Metadata_Helpers.Clean_Metadata_Name (Target_Name);
   begin
      if Clean'Length = 0 then
         return No_Symbol;
      end if;

      for I in 1 .. Symbol_Count (Analysis) loop
         declare
            S : constant Symbol_Info := Symbol_At (Analysis, I);
         begin
            if Target_Name_Matches (Analysis, S, Clean) then
               return S.Id;
            end if;
         end;
      end loop;

      return No_Symbol;
   end Find_Metadata_Target_Direct;

   function Resolve_Renamed_Metadata_Target
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Alias    : Editor.Ada_Language_Model.Symbol_Info;
      Depth    : Natural := 0)
      return Editor.Ada_Language_Model.Symbol_Id
   is
      Target : constant String := Editor.Ada_Declaration_Parser.Metadata_Helpers.Clean_Metadata_Name (To_String (Alias.Target_Name));
   begin
      if Depth > 8 or else Target = "" then
         return No_Symbol;
      end if;

      declare
         Direct : constant Symbol_Id := Find_Metadata_Target_Direct (Analysis, Target);
      begin
         if Direct = No_Symbol then
            return No_Symbol;
         elsif Natural (Direct) <= Symbol_Count (Analysis) then
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, Positive (Direct));
            begin
               if S.Kind = Symbol_Rename or else S.Flags.Is_Rename then
                  declare
                     Inner : constant Symbol_Id :=
                       Resolve_Renamed_Metadata_Target (Analysis, S, Depth + 1);
                  begin
                     if Inner /= No_Symbol then
                        return Inner;
                     end if;
                  end;
               end if;
            end;
         end if;

         return Direct;
      end;
   end Resolve_Renamed_Metadata_Target;

   function Selected_Prefix_Matches_Target
     (Analysis        : Editor.Ada_Language_Model.Analysis_Result;
      Actual_Parent   : String;
      Requested_Prefix : String) return Boolean
   is
      Actual : constant String := Normalize_Name (Actual_Parent);
      Wanted : constant String := Normalize_Name (Requested_Prefix);
   begin
      if Wanted = "" then
         return True;
      elsif Actual = Wanted or else Ends_With (Actual, "." & Wanted) then
         return True;
      end if;

      declare
         Prefix_Symbol : constant Symbol_Id := Find_Metadata_Target_Direct (Analysis, Requested_Prefix);
      begin
         if Prefix_Symbol /= No_Symbol
           and then Natural (Prefix_Symbol) <= Symbol_Count (Analysis)
         then
            declare
               Prefix_Info : constant Symbol_Info :=
                 Symbol_At (Analysis, Positive (Prefix_Symbol));
            begin
               if Prefix_Info.Kind = Symbol_Rename
                 or else Prefix_Info.Flags.Is_Rename
               then
                  declare
                     Renamed : constant Symbol_Id :=
                       Resolve_Renamed_Metadata_Target (Analysis, Prefix_Info);
                  begin
                     if Renamed /= No_Symbol
                       and then Natural (Renamed) <= Symbol_Count (Analysis)
                     then
                        declare
                           Renamed_Info : constant Symbol_Info :=
                             Symbol_At (Analysis, Positive (Renamed));
                           Renamed_Name : constant String :=
                             Normalize_Name (Qualified_Name (Analysis, Renamed_Info));
                        begin
                           return Actual = Renamed_Name
                             or else Ends_With (Actual, "." & Renamed_Name);
                        end;
                     end if;
                  end;
               end if;
            end;
         end if;
      end;

      return False;
   end Selected_Prefix_Matches_Target;

   function Find_Metadata_Target
     (Analysis    : Editor.Ada_Language_Model.Analysis_Result;
      Target_Name : String) return Editor.Ada_Language_Model.Symbol_Id is
      Clean : constant String := Editor.Ada_Declaration_Parser.Metadata_Helpers.Clean_Metadata_Name (Target_Name);
      Leaf   : constant String :=
        Editor.Ada_Declaration_Parser.Legality_Profile_Helpers.Last_Selected_Name_Part
          (Clean);
      Prefix : constant String :=
        (if Leaf = Clean then ""
         else Clean (Clean'First .. Clean'Last - Leaf'Length - 1));
      Direct : Symbol_Id := No_Symbol;
   begin
      if Clean'Length = 0 then
         return No_Symbol;
      end if;

      Direct := Find_Metadata_Target_Direct (Analysis, Clean);
      if Direct /= No_Symbol
        and then Natural (Direct) <= Symbol_Count (Analysis)
      then
         declare
            Direct_Info : constant Symbol_Info :=
              Symbol_At (Analysis, Positive (Direct));
         begin
            if Direct_Info.Kind = Symbol_Rename
              or else Direct_Info.Flags.Is_Rename
            then
               declare
                  Renamed : constant Symbol_Id :=
                    Resolve_Renamed_Metadata_Target (Analysis, Direct_Info);
               begin
                  if Renamed /= No_Symbol then
                     return Renamed;
                  end if;
               end;
            end if;
         end;
         return Direct;
      end if;

      if Prefix /= "" and then Leaf /= "" then
         for I in 1 .. Symbol_Count (Analysis) loop
            declare
               S : constant Symbol_Info := Symbol_At (Analysis, I);
            begin
               if To_String (S.Normalized_Name) = Normalize_Name (Leaf)
                 and then Selected_Prefix_Matches_Target
                   (Analysis, Parent_Selected_Name (Analysis, S), Prefix)
               then
                  return S.Id;
               end if;
            end;
         end loop;
      end if;

      return No_Symbol;
   end Find_Metadata_Target;

   procedure Apply_Metadata_To_Target
     (Analysis   : in out Editor.Ada_Language_Model.Analysis_Result;
      Target_Name : String;
      Flags      : Editor.Ada_Language_Model.Declaration_Flags)
   is
      Target : constant Symbol_Id := Find_Metadata_Target (Analysis, Target_Name);
   begin
      if Target /= No_Symbol then
         Merge_Symbol_Flags (Analysis, Target, Flags);
      end if;
   end Apply_Metadata_To_Target;

end Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers;
