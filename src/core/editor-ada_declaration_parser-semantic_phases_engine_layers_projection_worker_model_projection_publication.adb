with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers;
with Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Pragma_Helpers;
with Editor.Ada_Declaration_Parser.Representation_Application;
with Editor.Ada_Declaration_Parser.Representation_Metadata;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication is

   procedure Collect_Facts
     (Phase                   : in out Context;
      Declaration_Is_Complete : Boolean;
      Declarations            : Declaration_Collection.Context;
      Analysis                : Editor.Ada_Language_Model.Analysis_Result;
      Tree                    : Editor.Ada_Syntax_Tree.Tree_Type)
   is
      use Editor.Ada_Language_Model;
      use Editor.Ada_Syntax_Tree;

      function First_Child_Label
        (Parent : Node_Id;
         Kind   : Node_Kind) return String
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
           .First_Child_Label (Tree, Parent, Kind);
      end First_Child_Label;

      function Has_Child_Kind
        (Parent : Node_Id;
         Kind   : Node_Kind) return Boolean
      is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
           .Has_Child_Kind (Tree, Parent, Kind);
      end Has_Child_Kind;

      function Ancestor_Symbol (Id : Node_Id) return Symbol_Id is
         P : Node_Id;
      begin
         if Id = No_Node then
            return No_Symbol;
         end if;

         P := Node (Tree, Id).Parent;
         while P /= No_Node loop
            if Natural (P) >= Natural (Declarations.Node_Symbols'First)
              and then Natural (P) <= Natural (Declarations.Node_Symbols'Last)
              and then Declarations.Node_Symbols (Positive (P)) /= No_Symbol
            then
               return Declarations.Node_Symbols (Positive (P));
            end if;
            P := Node (Tree, P).Parent;
         end loop;
         return No_Symbol;
      end Ancestor_Symbol;

      function Find_Metadata_Target (Target_Name : String) return Symbol_Id is
      begin
         return Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
           .Find_Metadata_Target (Analysis, Target_Name);
      end Find_Metadata_Target;

      function Parent_Representation_Target
        (Component_Node : Node_Id) return Symbol_Id
      is
      begin
         return Editor.Ada_Declaration_Parser.Representation_Application
           .Parent_Representation_Target
             (Tree => Tree,
              First_Child_Label => First_Child_Label'Unrestricted_Access,
              Find_Metadata_Target => Find_Metadata_Target'Unrestricted_Access,
              Component_Node => Component_Node);
      end Parent_Representation_Target;

      procedure Append_Metadata_Fact (Fact : Phase_Types.Metadata_Fact_Info) is
      begin
         Phase.Metadata_Fact_Count := Phase.Metadata_Fact_Count + 1;
         Phase.Metadata_Facts (Phase.Metadata_Fact_Count) := Fact;
      end Append_Metadata_Fact;
   begin
      Phase_Types.Require_Phase
        (Declaration_Is_Complete,
         "publication fact collection requires declaration collection");

      for I in 1 .. Node_Count (Tree) loop
         declare
            N : constant Node_Info := Node_At (Tree, I);
            Fact : Phase_Types.Metadata_Fact_Info;
         begin
            case N.Kind is
               when Node_Aspect_Specification =>
                  Fact :=
                    (Kind => N.Kind,
                     Node => N,
                     Node_Ref => N.Id,
                     Owner => Ancestor_Symbol (N.Id),
                     Source_Span => N.Source_Span,
                     Label_Text => To_Unbounded_String (To_String (N.Label)),
                     Named_Aspect => Null_Unbounded_String,
                     Value_Child => Null_Unbounded_String,
                     Generic_Formal => Null_Unbounded_String,
                     Generic_Actual => Null_Unbounded_String,
                     Has_Generic_Association_Children => False,
                     Representation_Target_Text => Null_Unbounded_String,
                     Representation_Target_Id => No_Symbol,
                     Pragma_Name => Null_Unbounded_String,
                     Pragma_Placement => Pragma_Placement_Kind'First,
                     Pragma_Target_Name => Null_Unbounded_String,
                     Pragma_Argument_Count => 0,
                     Pragma_Named_Argument_Count => 0);
                  Append_Metadata_Fact (Fact);
               when Node_Aspect_Association =>
                  Fact :=
                    (Kind => N.Kind,
                     Node => N,
                     Node_Ref => N.Id,
                     Owner => Ancestor_Symbol (N.Id),
                     Source_Span => N.Source_Span,
                     Label_Text => To_Unbounded_String (To_String (N.Label)),
                     Named_Aspect =>
                       To_Unbounded_String
                         (First_Child_Label (N.Id, Node_Aspect_Name)),
                     Value_Child =>
                       To_Unbounded_String
                         (First_Child_Label (N.Id, Node_Aspect_Value)),
                     Generic_Formal => Null_Unbounded_String,
                     Generic_Actual => Null_Unbounded_String,
                     Has_Generic_Association_Children => False,
                     Representation_Target_Text => Null_Unbounded_String,
                     Representation_Target_Id => No_Symbol,
                     Pragma_Name => Null_Unbounded_String,
                     Pragma_Placement => Pragma_Placement_Kind'First,
                     Pragma_Target_Name => Null_Unbounded_String,
                     Pragma_Argument_Count => 0,
                     Pragma_Named_Argument_Count => 0);
                  Append_Metadata_Fact (Fact);
               when Node_Generic_Actual_Part =>
                  Fact :=
                    (Kind => N.Kind,
                     Node => N,
                     Node_Ref => N.Id,
                     Owner => Ancestor_Symbol (N.Id),
                     Source_Span => N.Source_Span,
                     Label_Text => To_Unbounded_String (To_String (N.Label)),
                     Named_Aspect => Null_Unbounded_String,
                     Value_Child => Null_Unbounded_String,
                     Generic_Formal => Null_Unbounded_String,
                     Generic_Actual => Null_Unbounded_String,
                     Has_Generic_Association_Children =>
                       Has_Child_Kind (N.Id, Node_Generic_Actual_Association),
                     Representation_Target_Text => Null_Unbounded_String,
                     Representation_Target_Id => No_Symbol,
                     Pragma_Name => Null_Unbounded_String,
                     Pragma_Placement => Pragma_Placement_Kind'First,
                     Pragma_Target_Name => Null_Unbounded_String,
                     Pragma_Argument_Count => 0,
                     Pragma_Named_Argument_Count => 0);
                  Append_Metadata_Fact (Fact);
               when Node_Generic_Actual_Association =>
                  declare
                     Owner_Id : Symbol_Id := Ancestor_Symbol (N.Id);
                  begin
                     if not (Owner_Id /= No_Symbol
                             and then Symbol (Analysis, Owner_Id).Kind =
                               Symbol_Instantiation)
                     then
                        Owner_Id := No_Symbol;
                        for J in 1 .. Symbol_Count (Analysis) loop
                           declare
                              S : constant Symbol_Info := Symbol_At (Analysis, J);
                           begin
                              if S.Kind = Symbol_Instantiation
                                and then S.Source_Span.Start_Line =
                                  N.Source_Span.Start_Line
                              then
                                 Owner_Id := S.Id;
                                 exit;
                              end if;
                           end;
                        end loop;
                        if Owner_Id = No_Symbol then
                           Owner_Id := Ancestor_Symbol (N.Id);
                        end if;
                     end if;
                     Fact :=
                       (Kind => N.Kind,
                        Node => N,
                        Node_Ref => N.Id,
                        Owner => Owner_Id,
                        Source_Span => N.Source_Span,
                        Label_Text => To_Unbounded_String (To_String (N.Label)),
                        Named_Aspect => Null_Unbounded_String,
                        Value_Child => Null_Unbounded_String,
                        Generic_Formal =>
                          To_Unbounded_String
                            (First_Child_Label (N.Id, Node_Generic_Actual_Formal)),
                        Generic_Actual =>
                          To_Unbounded_String
                            (First_Child_Label (N.Id, Node_Generic_Actual_Value)),
                        Has_Generic_Association_Children => False,
                        Representation_Target_Text => Null_Unbounded_String,
                        Representation_Target_Id => No_Symbol,
                        Pragma_Name => Null_Unbounded_String,
                        Pragma_Placement => Pragma_Placement_Kind'First,
                        Pragma_Target_Name => Null_Unbounded_String,
                        Pragma_Argument_Count => 0,
                        Pragma_Named_Argument_Count => 0);
                  end;
                  Append_Metadata_Fact (Fact);
               when Node_Representation_Clause =>
                  Fact :=
                    (Kind => N.Kind,
                     Node => N,
                     Node_Ref => N.Id,
                     Owner => Ancestor_Symbol (N.Id),
                     Source_Span => N.Source_Span,
                     Label_Text => To_Unbounded_String (To_String (N.Label)),
                     Named_Aspect => Null_Unbounded_String,
                     Value_Child => Null_Unbounded_String,
                     Generic_Formal => Null_Unbounded_String,
                     Generic_Actual => Null_Unbounded_String,
                     Has_Generic_Association_Children => False,
                     Representation_Target_Text =>
                       To_Unbounded_String
                         (First_Child_Label (N.Id, Node_Representation_Target)),
                     Representation_Target_Id => No_Symbol,
                     Pragma_Name => Null_Unbounded_String,
                     Pragma_Placement => Pragma_Placement_Kind'First,
                     Pragma_Target_Name => Null_Unbounded_String,
                     Pragma_Argument_Count => 0,
                     Pragma_Named_Argument_Count => 0);
                  Append_Metadata_Fact (Fact);
               when Node_Representation_Component_Clause
                    | Node_Representation_Mod_Clause =>
                  Fact :=
                    (Kind => N.Kind,
                     Node => N,
                     Node_Ref => N.Id,
                     Owner => Ancestor_Symbol (N.Id),
                     Source_Span => N.Source_Span,
                     Label_Text => To_Unbounded_String (To_String (N.Label)),
                     Named_Aspect => Null_Unbounded_String,
                     Value_Child => Null_Unbounded_String,
                     Generic_Formal => Null_Unbounded_String,
                     Generic_Actual => Null_Unbounded_String,
                     Has_Generic_Association_Children => False,
                     Representation_Target_Text => Null_Unbounded_String,
                     Representation_Target_Id =>
                       Parent_Representation_Target (N.Id),
                     Pragma_Name => Null_Unbounded_String,
                     Pragma_Placement => Pragma_Placement_Kind'First,
                     Pragma_Target_Name => Null_Unbounded_String,
                     Pragma_Argument_Count => 0,
                     Pragma_Named_Argument_Count => 0);
                  Append_Metadata_Fact (Fact);
               when Node_Pragma | Node_Pragma_Statement =>
                  Fact :=
                    (Kind => N.Kind,
                     Node => N,
                     Node_Ref => N.Id,
                     Owner => Ancestor_Symbol (N.Id),
                     Source_Span => N.Source_Span,
                     Label_Text => To_Unbounded_String (To_String (N.Label)),
                     Named_Aspect => Null_Unbounded_String,
                     Value_Child => Null_Unbounded_String,
                     Generic_Formal => Null_Unbounded_String,
                     Generic_Actual => Null_Unbounded_String,
                     Has_Generic_Association_Children => False,
                     Representation_Target_Text => Null_Unbounded_String,
                     Representation_Target_Id => No_Symbol,
                     Pragma_Name =>
                       To_Unbounded_String
                         (Editor.Ada_Declaration_Parser.Pragma_Helpers
                            .Pragma_Metadata_Name (To_String (N.Label))),
                     Pragma_Placement =>
                       Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                         .Pragma_Placement_For_Node
                           (Tree, N, Ancestor_Symbol (N.Id)),
                     Pragma_Target_Name =>
                       To_Unbounded_String
                         (Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                            .Pragma_Metadata_Target (N)),
                     Pragma_Argument_Count =>
                       Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                         .Pragma_Metadata_Argument_Count (N),
                     Pragma_Named_Argument_Count =>
                       Editor.Ada_Declaration_Parser.Declaration_Projection_Metadata_Helpers
                         .Pragma_Metadata_Named_Argument_Count (N));
                  Append_Metadata_Fact (Fact);
               when Node_Variant_Part =>
                  Fact :=
                    (Kind => N.Kind,
                     Node => N,
                     Node_Ref => N.Id,
                     Owner => Ancestor_Symbol (N.Id),
                     Source_Span => N.Source_Span,
                     Label_Text => To_Unbounded_String (To_String (N.Label)),
                     Named_Aspect => Null_Unbounded_String,
                     Value_Child => Null_Unbounded_String,
                     Generic_Formal => Null_Unbounded_String,
                     Generic_Actual => Null_Unbounded_String,
                     Has_Generic_Association_Children => False,
                     Representation_Target_Text => Null_Unbounded_String,
                     Representation_Target_Id => No_Symbol,
                     Pragma_Name => Null_Unbounded_String,
                     Pragma_Placement => Pragma_Placement_Kind'First,
                     Pragma_Target_Name => Null_Unbounded_String,
                     Pragma_Argument_Count => 0,
                     Pragma_Named_Argument_Count => 0);
                  Append_Metadata_Fact (Fact);
               when others =>
                  null;
            end case;
         end;
      end loop;

      Phase.Facts_Collected := True;
   end Collect_Facts;

   procedure Apply_Aspects
     (Phase                  : in out Context;
      Analysis               : in out Editor.Ada_Language_Model.Analysis_Result;
      Representation_Context :
        Editor.Ada_Declaration_Parser.Representation_Application.Application_Context)
   is
      use Editor.Ada_Language_Model;
      use Editor.Text_Helpers;
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      Phase_Types.Require_Phase
        (Phase.Facts_Collected,
         "aspect publication requires collected metadata facts");

      for I in 1 .. Phase.Metadata_Fact_Count loop
         declare
            M : constant Phase_Types.Metadata_Fact_Info :=
              Phase.Metadata_Facts (I);
         begin
            if M.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Specification then
               declare
                  Flags : Declaration_Flags := (others => False);
               begin
                  Flags.Has_Aspect_Specification := True;
                  if M.Owner /= No_Symbol then
                     Merge_Symbol_Flags (Analysis, M.Owner, Flags);
                     Phase.Aspect_Facts_Applied :=
                       Phase.Aspect_Facts_Applied + 1;
                  end if;
               end;
            elsif M.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Association then
               declare
                  Label_Text : constant String := To_String (M.Label_Text);
                  Arrow : constant Natural :=
                    Ada.Strings.Fixed.Index (Label_Text, "=>");
                  Named_Aspect : constant String := To_String (M.Named_Aspect);
                  Value_Child : constant String := To_String (M.Value_Child);
                  Aspect_Name : constant String :=
                    (if Named_Aspect /= "" then Trim (Named_Aspect)
                     elsif Arrow /= 0 then
                       Trim (Label_Text (Label_Text'First .. Arrow - 1))
                     else Trim (Label_Text));
                  Raw_Aspect_Value : constant String :=
                    (if Named_Aspect /= ""
                       and then Arrow = 0
                       and then Normalize_Name (Value_Child) =
                         Normalize_Name (Named_Aspect)
                     then ""
                     elsif Named_Aspect /= "" then Trim (Value_Child)
                     elsif Value_Child /= "" then Trim (Value_Child)
                     elsif Arrow /= 0 and then Arrow + 2 <= Label_Text'Last then
                        Trim (Label_Text (Arrow + 2 .. Label_Text'Last))
                     else "");
                  Aspect_Value : constant String :=
                    Editor.Ada_Declaration_Parser.Representation_Metadata
                      .Aspect_Default_Value (Aspect_Name, Raw_Aspect_Value);
               begin
                  Editor.Ada_Declaration_Parser.Representation_Application
                    .Apply_Representation_Aspect
                      (Representation_Context,
                       Analysis,
                       M.Owner,
                       Aspect_Name,
                       Aspect_Value,
                       M.Source_Span);
                  Phase.Aspect_Facts_Applied :=
                    Phase.Aspect_Facts_Applied + 1;
               end;
            end if;
         end;
      end loop;
   end Apply_Aspects;

   procedure Finish
     (Phase                         : in out Context;
      Analysis                      : in out Editor.Ada_Language_Model.Analysis_Result;
      Executable_Binding_Is_Complete : Boolean;
      Legality_Is_Complete          : Boolean)
   is
      use Editor.Ada_Language_Model;
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      Phase_Types.Require_Phase
        (Phase.Facts_Collected,
         "publication requires collected metadata facts");
      Phase_Types.Require_Phase
        (Executable_Binding_Is_Complete,
         "publication finalization requires executable binding");
      Phase_Types.Require_Phase
        (Legality_Is_Complete,
         "publication finalization requires legality checks");

      for I in 1 .. Phase.Metadata_Fact_Count loop
         declare
            M : constant Phase_Types.Metadata_Fact_Info :=
              Phase.Metadata_Facts (I);
         begin
            if M.Kind = Editor.Ada_Syntax_Tree.Node_Pragma
              or else M.Kind = Editor.Ada_Syntax_Tree.Node_Pragma_Statement
            then
               declare
                  Flags : Declaration_Flags := (others => False);
               begin
                  Flags.Has_Pragma_Metadata := True;
                  if M.Owner /= No_Symbol then
                     Merge_Symbol_Flags (Analysis, M.Owner, Flags);
                  end if;

                  Add_Pragma_Metadata
                    (Analysis,
                     Name                 => To_String (M.Pragma_Name),
                     Placement            => M.Pragma_Placement,
                     Scope                =>
                       (if M.Owner = No_Symbol then Root_Scope
                        else Scope_Id (M.Owner)),
                     Target_Name          => To_String (M.Pragma_Target_Name),
                     Argument_Count       => M.Pragma_Argument_Count,
                     Named_Argument_Count => M.Pragma_Named_Argument_Count,
                     Source_Span          =>
                       Editor.Ada_Declaration_Parser.Declaration_Projection_Helpers
                         .To_Model_Range (M.Source_Span));
                  Phase.Pragma_Facts_Applied :=
                    Phase.Pragma_Facts_Applied + 1;
               end;
            elsif M.Kind = Editor.Ada_Syntax_Tree.Node_Variant_Part then
               declare
                  Flags : Declaration_Flags := (others => False);
               begin
                  Flags.Has_Variant_Record_Metadata := True;
                  if M.Owner /= No_Symbol then
                     Merge_Symbol_Flags (Analysis, M.Owner, Flags);
                     Phase.Variant_Facts_Applied :=
                       Phase.Variant_Facts_Applied + 1;
                  end if;
               end;
            end if;
         end;
      end loop;

      Phase.Completed := True;
   end Finish;

   function Facts_Are_Collected (Phase : Context) return Boolean is
   begin
      return Phase.Facts_Collected;
   end Facts_Are_Collected;

   function Is_Complete (Phase : Context) return Boolean is
   begin
      return Phase.Completed;
   end Is_Complete;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Publication;
