with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types.Call_Text_Helpers;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Operator_Helpers;
with Editor.Ada_Expression_Types.Status_Helpers;

package body Editor.Ada_Expression_Types.Call_Inference is

   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Kind;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Call_Resolution.Call_Resolution_Status;

   function Trim (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean
     renames Editor.Ada_Expression_Types.Status_Helpers.Contains;

   function Region_For_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id
     renames Editor.Ada_Expression_Types.Inference_Support.Region_For_Line;

   function Simple_Name (Text : String) return String
     renames Editor.Ada_Expression_Types.Inference_Support.Simple_Name;

   function Simple_Subtype_Compatible (Left : String; Right : String) return Boolean
     renames Editor.Ada_Expression_Types.Operator_Helpers.Simple_Subtype_Compatible;

   function Extract_Designator_Before_Call (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Extract_Designator_Before_Call;

   function Actual_Expression_Text (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Actual_Expression_Text;

   function Named_Actual_Formal_Name (Text : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Named_Actual_Formal_Name;

   function Formal_Subtype_By_Position (Callable_Label : String; Position : Positive) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Formal_Subtype_By_Position;

   function Formal_Subtype_By_Name (Callable_Label : String; Name : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Formal_Subtype_By_Name;

   function Infer_Text_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Infer_Text_Subtype;

   function Actual_Position_In_Call
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Call : Editor.Ada_Syntax_Tree.Node_Id;
      Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Actual_Position_In_Call;

   function Callable_Result_Subtype (Callable_Label : String) return String
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Callable_Result_Subtype;

   function Is_Class_Wide_Subtype (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Is_Class_Wide_Subtype;

   function Looks_Primitive_Call_Designator (Text : String) return Boolean
     renames Editor.Ada_Expression_Types.Call_Text_Helpers.Looks_Primitive_Call_Designator;

   procedure Apply_Call_Actual_Type_Resolution
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Decl : Editor.Ada_Direct_Visibility.Declaration_Id := Editor.Ada_Direct_Visibility.No_Declaration;
      Candidate_Count : Natural := 0;
      Compatible : Natural := 0;
      Mismatch : Natural := 0;
      Unknown : Natural := 0;
      Actual_Count : Natural := 0;
   begin
      Info.Call_Actual_Type_Status := Call_Actual_Type_Not_Call;
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement)
      then
         return;
      end if;

      declare
         Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
           Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Node.Id);
      begin
         if Resolution.Declaration /= Editor.Ada_Direct_Visibility.No_Declaration then
            Decl := Resolution.Declaration;
            Candidate_Count := Resolution.Candidate_Count;
         elsif Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Pre_Profile or else
           Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Profile_Match
         then
            Info.Call_Actual_Type_Status := Call_Actual_Type_Ambiguous_Call;
            Info.Call_Actual_Type_Candidate_Count := Resolution.Candidate_Count;
            return;
         end if;
      end;

      if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
         declare
            Designator : constant String := Extract_Designator_Before_Call (To_String (Node.Label));
            Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
              Editor.Ada_Direct_Visibility.Lookup_Visible
                (Visibility, Regions, Region, Designator);
         begin
            Candidate_Count := Lookup.Match_Count;
            if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
               Decl := Lookup.Declaration;
            elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
               Info.Call_Actual_Type_Status := Call_Actual_Type_Ambiguous_Call;
               Info.Call_Actual_Type_Candidate_Count := Lookup.Match_Count;
               Info.Status := Expression_Type_Call_Ambiguous;
               Info.Candidate_Count := Lookup.Match_Count;
               return;
            else
               declare
                  Wanted : constant String := Normalize (Simple_Name (Designator));
               begin
                  for I in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
                     declare
                        D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                          Editor.Ada_Direct_Visibility.Declaration_At (Visibility, I);
                     begin
                        if Normalize (To_String (D.Name)) = Wanted
                          and then (D.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
                                    or else D.Kind = Editor.Ada_Direct_Visibility.Declaration_Entry
                                    or else D.Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram)
                        then
                           if Decl /= Editor.Ada_Direct_Visibility.No_Declaration then
                              Info.Call_Actual_Type_Status := Call_Actual_Type_Ambiguous_Call;
                              Info.Call_Actual_Type_Candidate_Count := Candidate_Count + 1;
                              Info.Status := Expression_Type_Call_Ambiguous;
                              Info.Candidate_Count := Candidate_Count + 1;
                              return;
                           end if;
                           Decl := D.Id;
                           Candidate_Count := 1;
                        end if;
                     end;
                  end loop;

                  if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
                     Info.Call_Actual_Type_Status := Call_Actual_Type_Unresolved_Call;
                     Info.Status := Expression_Type_Call_Unresolved;
                     return;
                  end if;
               end;
            end if;
         end;
      end if;

      Info.Call_Actual_Type_Selected_Declaration := Decl;
      Info.Call_Actual_Type_Candidate_Count := Candidate_Count;
      Info.Declaration := Decl;
      Info.Candidate_Count := Candidate_Count;

      declare
         D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl);
         D_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, D.Node);
         Label : constant String := To_String (D_Node.Label);
      begin
         for I in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Formal_Name : constant String :=
                 (if Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association then
                    Named_Actual_Formal_Name (To_String (Child.Label)) else "");
               Formal_Subtype : constant String :=
                 (if Formal_Name /= "" then Formal_Subtype_By_Name (Label, Formal_Name)
                  else Formal_Subtype_By_Position (Label, Positive (I)));
               Actual_Subtype : constant String :=
                 Infer_Text_Subtype
                   (Tree, Regions, Visibility, Static, Region,
                    Actual_Expression_Text (To_String (Child.Label)));
            begin
               if Child.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
                 Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
                 Child.Kind = Editor.Ada_Syntax_Tree.Node_Association or else
                 Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
               then
                  Actual_Count := Actual_Count + 1;
                  if Formal_Subtype = "" or else Actual_Subtype = "" then
                     Unknown := Unknown + 1;
                  elsif Simple_Subtype_Compatible (Actual_Subtype, Formal_Subtype) then
                     Compatible := Compatible + 1;
                  else
                     Mismatch := Mismatch + 1;
                  end if;
               end if;
            end;
         end loop;
      end;

      Info.Call_Actual_Type_Compatible_Count := Compatible;
      Info.Call_Actual_Type_Mismatch_Count := Mismatch;
      Info.Call_Actual_Type_Unknown_Count := Unknown;

      if Actual_Count = 0 then
         Info.Call_Actual_Type_Status := Call_Actual_Type_All_Compatible;
         Info.Status := Expression_Type_Call_Resolved;
      elsif Mismatch /= 0 then
         Info.Call_Actual_Type_Status := Call_Actual_Type_Actual_Mismatch;
         Info.Status := Expression_Type_Call_Ambiguous;
      elsif Unknown /= 0 then
         Info.Call_Actual_Type_Status := Call_Actual_Type_Actual_Unknown;
         Info.Status := Expression_Type_Call_Unresolved;
      else
         Info.Call_Actual_Type_Status := Call_Actual_Type_All_Compatible;
         Info.Status := Expression_Type_Call_Resolved;
      end if;
   end Apply_Call_Actual_Type_Resolution;

   procedure Apply_Dispatching_Call_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      pragma Unreferenced (Region);
      Decl : constant Editor.Ada_Direct_Visibility.Declaration_Id :=
        Info.Call_Actual_Type_Selected_Declaration;
      Controlling_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Formal_One : Ada.Strings.Unbounded.Unbounded_String;
      Actual_One : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Info.Dispatching_Call_Status := Dispatching_Call_Not_Call;
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement)
      then
         return;
      end if;

      if Info.Call_Actual_Type_Status = Call_Actual_Type_Ambiguous_Call then
         Info.Dispatching_Call_Status := Dispatching_Call_Target_Ambiguous;
         Info.Dispatching_Call_Ambiguous_Count := 1;
         return;
      elsif Info.Call_Actual_Type_Status = Call_Actual_Type_Unresolved_Call or else
        Decl = Editor.Ada_Direct_Visibility.No_Declaration
      then
         Info.Dispatching_Call_Status := Dispatching_Call_Target_Unresolved;
         Info.Dispatching_Call_Unknown_Count := 1;
         return;
      end if;

      declare
         D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl);
         D_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, D.Node);
         Label : constant String := To_String (D_Node.Label);
      begin
         if not (D.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram or else
                 D.Kind = Editor.Ada_Direct_Visibility.Declaration_Entry or else
                 D.Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram)
         then
            Info.Dispatching_Call_Status := Dispatching_Call_Controlling_Unknown;
            Info.Dispatching_Call_Unknown_Count := 1;
            return;
         end if;

         Info.Dispatching_Call_Primitive_Count := 1;
         Formal_One := To_Unbounded_String (Formal_Subtype_By_Position (Label, 1));
         Result_Subtype := To_Unbounded_String (Callable_Result_Subtype (Label));

         if Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) >= 1 then
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, 1);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
            begin
               Actual_One := To_Unbounded_String
                 (Infer_Text_Subtype
                    (Tree, Regions, Visibility, Static,
                     Region_For_Line (Regions, Child.Source_Span.Start_Line),
                     Actual_Expression_Text (To_String (Child.Label))));
            end;
         end if;

         if To_String (Actual_One) /= "" then
            Controlling_Subtype := Actual_One;
         else
            Controlling_Subtype := Formal_One;
         end if;

         Info.Dispatching_Call_Controlling_Subtype := Controlling_Subtype;
         Info.Normalized_Dispatching_Call_Controlling_Subtype :=
           To_Unbounded_String (Normalize (To_String (Controlling_Subtype)));
         Info.Dispatching_Call_Result_Subtype := Result_Subtype;
         Info.Normalized_Dispatching_Call_Result_Subtype :=
           To_Unbounded_String (Normalize (To_String (Result_Subtype)));

         if Is_Class_Wide_Subtype (To_String (Formal_One)) or else
           Is_Class_Wide_Subtype (To_String (Actual_One)) then
            Info.Dispatching_Call_Status := Dispatching_Call_Dynamic_Dispatch;
            Info.Dispatching_Call_Controlling_Operand_Count := 1;
         elsif Is_Class_Wide_Subtype (To_String (Result_Subtype)) then
            Info.Dispatching_Call_Status := Dispatching_Call_Controlling_Result;
            Info.Dispatching_Call_Controlling_Result_Count := 1;
         elsif Looks_Primitive_Call_Designator (To_String (Node.Label)) and then
           To_String (Formal_One) /= "" then
            Info.Dispatching_Call_Status := Dispatching_Call_Primitive_Target;
            Info.Dispatching_Call_Controlling_Operand_Count := 1;
         elsif To_String (Formal_One) /= "" or else To_String (Result_Subtype) /= "" then
            Info.Dispatching_Call_Status := Dispatching_Call_Static_Binding;
         else
            Info.Dispatching_Call_Status := Dispatching_Call_Controlling_Unknown;
            Info.Dispatching_Call_Unknown_Count := 1;
         end if;
      end;
   end Apply_Dispatching_Call_Inference;

   procedure Apply_Parameter_Association_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Parent : Editor.Ada_Syntax_Tree.Node_Info;
      Call   : Editor.Ada_Syntax_Tree.Node_Info;
      Assoc  : Editor.Ada_Syntax_Tree.Node_Info := Node;
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Formal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Text : constant String := Actual_Expression_Text (To_String (Node.Label));
      Decl : Editor.Ada_Direct_Visibility.Declaration_Id := Editor.Ada_Direct_Visibility.No_Declaration;
      Candidate_Count : Natural := 0;

      function Unique_Call_Target
        (Name : String) return Editor.Ada_Direct_Visibility.Declaration_Id
      is
         Wanted : constant String := Normalize (Name);
         Found  : Editor.Ada_Direct_Visibility.Declaration_Id :=
           Editor.Ada_Direct_Visibility.No_Declaration;
      begin
         if Wanted = "" then
            return Editor.Ada_Direct_Visibility.No_Declaration;
         end if;
         for I in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
            declare
               D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                 Editor.Ada_Direct_Visibility.Declaration_At (Visibility, I);
            begin
               if Normalize (To_String (D.Name)) = Wanted
                 and then (D.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
                           or else D.Kind = Editor.Ada_Direct_Visibility.Declaration_Entry)
               then
                  if Found /= Editor.Ada_Direct_Visibility.No_Declaration then
                     return Editor.Ada_Direct_Visibility.No_Declaration;
                  end if;
                  Found := D.Id;
               end if;
            end;
         end loop;
         return Found;
      end Unique_Call_Target;
   begin
      Info.Parameter_Association_Status := Parameter_Association_Not_Parameter;
      if Node.Parent = Editor.Ada_Syntax_Tree.No_Node then
         return;
      end if;
      Parent := Editor.Ada_Syntax_Tree.Node (Tree, Node.Parent);
      if Parent.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Association
      then
         Assoc := Parent;
         if Parent.Parent = Editor.Ada_Syntax_Tree.No_Node then
            return;
         end if;
         Call := Editor.Ada_Syntax_Tree.Node (Tree, Parent.Parent);
      elsif Parent.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement
      then
         Call := Parent;
      else
         return;
      end if;
      if not (Call.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
              Call.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement)
      then
         return;
      end if;

      if Info.Status = Expression_Type_Not_Checked then
         Info.Status := Expression_Type_Indeterminate;
      end if;
      Info.Parameter_Association_Call := Call.Id;
      Info.Parameter_Association_Position := Actual_Position_In_Call (Tree, Call.Id, Assoc);
      if Assoc.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association then
         Formal_Name := To_Unbounded_String (Named_Actual_Formal_Name (To_String (Assoc.Label)));
      end if;

      declare
         Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
           Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Call.Id);
      begin
         if Resolution.Declaration /= Editor.Ada_Direct_Visibility.No_Declaration then
            Decl := Resolution.Declaration;
            Candidate_Count := Resolution.Candidate_Count;
         end if;
      end;
      if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
         declare
            Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
              Editor.Ada_Direct_Visibility.Lookup_Visible
                (Visibility, Regions, Region, Extract_Designator_Before_Call (To_String (Call.Label)));
         begin
            Candidate_Count := Lookup.Match_Count;
            if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
               Decl := Lookup.Declaration;
            elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
               Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Ambiguous;
               Info.Candidate_Count := Lookup.Match_Count;
               return;
            else
               Decl := Unique_Call_Target
                 (Extract_Designator_Before_Call (To_String (Call.Label)));
               if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
                  Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Unresolved;
                  return;
               end if;
               Candidate_Count := 1;
            end if;
         end;
      end if;

      Info.Candidate_Count := Candidate_Count;
      if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
         Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Unresolved;
         return;
      end if;
      declare
         D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl);
         D_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, D.Node);
         Label : constant String := To_String (D_Node.Label);
      begin
         if To_String (Formal_Name) /= "" then
            Formal_Subtype := To_Unbounded_String
              (Formal_Subtype_By_Name (Label, To_String (Formal_Name)));
         elsif Info.Parameter_Association_Position /= 0 then
            Formal_Subtype := To_Unbounded_String
              (Formal_Subtype_By_Position (Label, Positive (Info.Parameter_Association_Position)));
         end if;
      end;

      if To_String (Formal_Subtype) = "" then
         Info.Parameter_Association_Status := Parameter_Association_Unknown;
         return;
      end if;

      Actual_Subtype := To_Unbounded_String
        (Infer_Text_Subtype (Tree, Regions, Visibility, Static, Region, Actual_Text));
      Info.Parameter_Association_Formal_Name := Formal_Name;
      Info.Normalized_Parameter_Association_Formal_Name :=
        To_Unbounded_String (Normalize (To_String (Formal_Name)));
      Info.Parameter_Association_Formal_Subtype := Formal_Subtype;
      Info.Normalized_Parameter_Association_Formal_Subtype :=
        To_Unbounded_String (Normalize (To_String (Formal_Subtype)));
      Info.Parameter_Association_Actual_Subtype := Actual_Subtype;
      Info.Normalized_Parameter_Association_Actual_Subtype :=
        To_Unbounded_String (Normalize (To_String (Actual_Subtype)));
      Info.Expected_Subtype := Formal_Subtype;
      Info.Normalized_Expected_Subtype := Info.Normalized_Parameter_Association_Formal_Subtype;
      Info.Expected_Status := Expected_Type_Context_Found;
      Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Found;

      if To_String (Actual_Subtype) /= "" and then
        Simple_Subtype_Compatible (To_String (Actual_Subtype), To_String (Formal_Subtype))
      then
         Info.Expected_Status := Expected_Type_Compatible;
         Info.Parameter_Association_Status := Parameter_Association_Compatible;
      elsif To_String (Info.Normalized_Subtype) /= "" and then
        Simple_Subtype_Compatible (To_String (Info.Normalized_Subtype), To_String (Formal_Subtype))
      then
         Info.Expected_Status := Expected_Type_Compatible;
         Info.Parameter_Association_Status := Parameter_Association_Compatible;
      elsif To_String (Actual_Subtype) = "" and then To_String (Info.Normalized_Subtype) = "" then
         Info.Expected_Status := Expected_Type_Propagated;
         Info.Inferred_Subtype := Formal_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         Info.Parameter_Association_Status := Parameter_Association_Expected_Propagated;
      else
         Info.Expected_Status := Expected_Type_Mismatch;
         Info.Parameter_Association_Status := Parameter_Association_Mismatch;
      end if;
   end Apply_Parameter_Association_Inference;

end Editor.Ada_Expression_Types.Call_Inference;
