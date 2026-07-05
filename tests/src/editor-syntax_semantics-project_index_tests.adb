with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Syntax;
with Editor.Syntax_Semantics;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Use_Visibility;
with Editor.Ada_Selected_Name_Resolution;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Call_Candidates;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Call_Profile_Filters;
with Editor.Ada_Call_Resolution;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Expected_Call_Filters;
with Editor.Ada_Implicit_Conversions;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Subtype_Compatibility;
with Editor.Ada_Type_Graph;
with Editor.Ada_Private_View_Visibility;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Limited_View_Rules;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Record_Storage_Order_Rules;
with Editor.Ada_Operational_Attribute_Rules;
with Editor.Ada_Aspect_Inheritance_Rules;
with Editor.Ada_Freezing_Interactions;
with Editor.Ada_Representation_Diagnostics;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_Generic_Contract_Diagnostics;
with Editor.Ada_Cross_Unit_Diagnostics;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Symbol_Resolver;
with Editor.Ada_Project_Index;
with Editor.Outline;
with Editor.Outline_Extractor;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings;
with Ada.Strings.Maps; use Ada.Strings.Maps;
with Ada.Strings.Fixed;
with System.WCh_Con; use System.WCh_Con;


--  Generated use-type compatibility for activated full suite.
use type Editor.Ada_Limited_View_Rules.Limited_View_Status;
use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
use type Editor.Ada_Representation_Legality.Address_Value_Status;
use type Editor.Syntax.Syntax_Kind;
use type Editor.Syntax.Token_Kind;
use type Editor.Syntax.Lexical_State;
use type Editor.Syntax.Token_Span;
use type Editor.Syntax.Token_Span_Array;
use type Editor.Syntax_Semantics.Semantic_Map;
use type Editor.Ada_Language_Model.Symbol_Kind;
use type Editor.Ada_Language_Model.Statement_Kind;
use type Editor.Ada_Language_Model.Symbol_Id;
use type Editor.Ada_Language_Model.Scope_Id;
use type Editor.Ada_Language_Model.Source_Range;
use type Editor.Ada_Language_Model.Declaration_Flags;
use type Editor.Ada_Language_Model.Symbol_Info;
use type Editor.Ada_Language_Model.Executable_Binding_Kind;
use type Editor.Ada_Language_Model.Executable_Binding_Info;
use type Editor.Ada_Language_Model.Visibility_Clause_Kind;
use type Editor.Ada_Language_Model.Visibility_Clause_Info;
use type Editor.Ada_Language_Model.Generic_Actual_Info;
use type Editor.Ada_Language_Model.Profile_Parameter_Mode;
use type Editor.Ada_Language_Model.Profile_Parameter_Info;
use type Editor.Ada_Language_Model.Generic_Formal_Type_Family;
use type Editor.Ada_Language_Model.Generic_Formal_Type_Info;
use type Editor.Ada_Language_Model.Pragma_Placement_Kind;
use type Editor.Ada_Language_Model.Pragma_Info;
use type Editor.Ada_Language_Model.Representation_Source_Form;
use type Editor.Ada_Language_Model.Representation_Clause_Kind;
use type Editor.Ada_Language_Model.Representation_Clause_Info;
use type Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
use type Editor.Ada_Language_Model.Representation_Component_Info;
use type Editor.Ada_Language_Model.Legality_Diagnostic_Severity;
use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
use type Editor.Ada_Language_Model.Freezing_Point_Kind;
use type Editor.Ada_Language_Model.Freezing_Point_Info;
use type Editor.Ada_Language_Model.Legality_Diagnostic_Info;
use type Editor.Ada_Language_Model.Analysis_Result;
use type Editor.Ada_Syntax_Tree.Node_Kind;
use type Editor.Ada_Syntax_Tree.Node_Id;
use type Editor.Ada_Syntax_Tree.Source_Range;
use type Editor.Ada_Syntax_Tree.Node_Info;
use type Editor.Ada_Syntax_Tree.Tree_Type;
use type Editor.Ada_Declarative_Regions.Region_Kind;
use type Editor.Ada_Declarative_Regions.Region_Id;
use type Editor.Ada_Declarative_Regions.Region_Info;
use type Editor.Ada_Declarative_Regions.Region_Model;
use type Editor.Ada_Direct_Visibility.Declaration_Kind;
use type Editor.Ada_Direct_Visibility.Declaration_Id;
use type Editor.Ada_Direct_Visibility.Lookup_Status;
use type Editor.Ada_Direct_Visibility.Declaration_Info;
use type Editor.Ada_Direct_Visibility.Lookup_Result;
use type Editor.Ada_Direct_Visibility.Visibility_Model;
use type Editor.Ada_Use_Visibility.Use_Clause_Kind;
use type Editor.Ada_Use_Visibility.Use_Clause_Id;
use type Editor.Ada_Use_Visibility.Use_Clause_Info;
use type Editor.Ada_Use_Visibility.Use_Visibility_Model;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Id;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Info;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Kind;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Status;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Id;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Info;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
use type Editor.Ada_Call_Candidates.Candidate_Source;
use type Editor.Ada_Call_Candidates.Call_Candidate_Status;
use type Editor.Ada_Call_Candidates.Call_Candidate_Id;
use type Editor.Ada_Call_Candidates.Call_Candidate_Info;
use type Editor.Ada_Call_Candidates.Call_Candidate_Model;
use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Status;
use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id;
use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Id;
use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Info;
use type Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Status;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Id;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Info;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
use type Editor.Ada_Call_Resolution.Call_Resolution_Id;
use type Editor.Ada_Call_Resolution.Call_Resolution_Info;
use type Editor.Ada_Call_Resolution.Call_Resolution_Model;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Kind;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Id;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Info;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Id;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model;
use type Editor.Ada_Implicit_Conversions.Implicit_Conversion_Status;
use type Editor.Ada_Implicit_Conversions.Implicit_Conversion_Info;
use type Editor.Ada_Static_Expressions.Static_Value_Status;
use type Editor.Ada_Static_Expressions.Static_Value_Info;
use type Editor.Ada_Static_Expressions.Static_Fixed_Type_Id;
use type Editor.Ada_Static_Expressions.Static_Fixed_Type_Info;
use type Editor.Ada_Static_Expressions.Static_Modular_Type_Id;
use type Editor.Ada_Static_Expressions.Static_Modular_Type_Info;
use type Editor.Ada_Static_Expressions.Static_Enumeration_Literal_Id;
use type Editor.Ada_Static_Expressions.Static_Enumeration_Literal_Info;
use type Editor.Ada_Static_Expressions.Static_Type_Bound_Id;
use type Editor.Ada_Static_Expressions.Static_Type_Bound_Info;
use type Editor.Ada_Static_Expressions.Static_Binding_Id;
use type Editor.Ada_Static_Expressions.Static_Binding_Kind;
use type Editor.Ada_Static_Expressions.Static_Binding_Info;
use type Editor.Ada_Static_Expressions.Static_Model;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Kind;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Status;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Info;
use type Editor.Ada_Generic_Contracts.Generic_Instance_Status;
use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
use type Editor.Ada_Generic_Contracts.Generic_Instance_Info;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Actual_Kind_Match;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Id;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info;
use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Status;
use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Id;
use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info;
use type Editor.Ada_Generic_Contracts.Generic_Contract_Model;
use type Editor.Ada_Subtype_Compatibility.Numeric_Family;
use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
use type Editor.Ada_Subtype_Compatibility.Compatibility_Info;
use type Editor.Ada_Type_Graph.Type_Category;
use type Editor.Ada_Type_Graph.Type_Relation_Status;
use type Editor.Ada_Type_Graph.Type_View_Status;
use type Editor.Ada_Type_Graph.Type_Id;
use type Editor.Ada_Type_Graph.Type_Info;
use type Editor.Ada_Type_Graph.Compatibility_Status;
use type Editor.Ada_Type_Graph.Type_Model;
use type Editor.Ada_Private_View_Visibility.Private_View_Status;
use type Editor.Ada_Private_View_Visibility.Private_View_Context_Status;
use type Editor.Ada_Private_View_Visibility.Private_View_Id;
use type Editor.Ada_Private_View_Visibility.Private_View_Info;
use type Editor.Ada_Private_View_Visibility.Private_View_Model;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry_Id;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Source;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Severity;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model;
use type Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key;
use type Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Status;
use type Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Id;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Status;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model;
use type Editor.Ada_Semantic_Diagnostic_Index.Feed_Entry;
use type Editor.Ada_Semantic_Diagnostic_Index.Feed_Severity;
use type Editor.Ada_Semantic_Diagnostic_Index.Feed_Source;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Status;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Query_Result;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Query_Set;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
use type Editor.Ada_Symbol_Resolver.Resolution_Result;
use type Editor.Ada_Project_Index.Indexed_File_Key;
use type Editor.Ada_Project_Index.Index_State;
use type Editor.Ada_Project_Index.Indexed_Unit_Role;
use type Editor.Ada_Project_Index.Indexed_Unit;
use type Editor.Ada_Project_Index.Unit_Resolution_Result;
use type Editor.Ada_Project_Index.Indexed_Symbol;
use type Editor.Ada_Project_Index.Index_Resolution_Result;
use type Editor.Ada_Project_Index.Unique_Target_Result;
use type Editor.Ada_Project_Index.Navigation_Target_Status;
use type Editor.Ada_Project_Index.Navigation_Candidate_Result;
use type Editor.Outline.Outline_Item_Kind;
use type Editor.Outline.Outline_Target_Kind;
use type Editor.Outline.Outline_Refresh_Source;
use type Editor.Outline.Outline_Refresh_Status;
use type Editor.Outline.Outline_Source_Class;
use type Editor.Outline.Outline_Freshness;
use type Editor.Outline.Outline_Snapshot_Identity;
use type Editor.Outline.Outline_Refresh_Failure_Kind;
use type Editor.Outline.Outline_Refresh_Result;
use type Editor.Outline.Outline_Item;
use type Editor.Outline.Outline_Item_Array;
use type Editor.Outline.Outline_State;
use type Editor.Outline.Outline_Summary;
use type Editor.Outline_Extractor.Extraction_Status;
use type Editor.Outline_Extractor.Extraction_Failure_Kind;
use type Editor.Outline_Extractor.Buffer_Text_Snapshot;
use type Editor.Outline_Extractor.Extraction_Result;

package body Editor.Syntax_Semantics.Project_Index_Tests is



   procedure Test_Project_Index_Invalidates_Buffer_And_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Indexed is" & ASCII.LF & "end Indexed;" & ASCII.LF,
           "indexed.ads");
      Index : Editor.Ada_Project_Index.Index_State;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/indexed.ads", Buffer_Token => 10, Buffer_Revision => 1,
         Lifecycle_Generation => 1, Analysis => Analysis);
      Assert (Editor.Ada_Project_Index.File_Count (Index) = 1,
              "project index should retain explicit open-buffer analyses");
      Assert (Editor.Ada_Project_Index.Symbol_Count (Index) >= 1,
              "project index should expose aggregate symbol counts");

      Editor.Ada_Project_Index.Invalidate_Buffer (Index, 10);
      Assert (Editor.Ada_Project_Index.File_Count (Index) = 0,
              "buffer invalidation should remove indexed targets for stale buffer tokens");

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/indexed.ads", Buffer_Token => 11, Buffer_Revision => 1,
         Lifecycle_Generation => 1, Analysis => Analysis);
      Editor.Ada_Project_Index.Invalidate_Path (Index, "src/indexed.ads");
      Assert (Editor.Ada_Project_Index.File_Count (Index) = 0,
              "file rename/delete invalidation should remove indexed targets by path");

      --  pass 183: exact lifecycle invalidation must normalize
      --  platform-native separators and trailing slashes, not only subtree
      --  invalidation.  Save-as/reload/revert hooks can carry either spelling.
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/indexed.ads", Buffer_Token => 12, Buffer_Revision => 1,
         Lifecycle_Generation => 1, Analysis => Analysis);
      Editor.Ada_Project_Index.Invalidate_Path (Index, "src\indexed.ads/");
      Assert (Editor.Ada_Project_Index.File_Count (Index) = 0,
              "exact path invalidation should normalize slashes and trailing separators");
   end Test_Project_Index_Invalidates_Buffer_And_Path;





   procedure Test_Project_Index_Current_And_Path_Containment_Normalizes_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Normalized_Path is" & ASCII.LF &
        "end Normalized_Path;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "normalized_path.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Fingerprint : constant Natural :=
        Editor.Ada_Language_Model.Fingerprint (Analysis);
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index,
         "src/normalized_path.ads",
         Buffer_Token => 77,
         Buffer_Revision => 3,
         Lifecycle_Generation => 9,
         Analysis => Analysis);

      Assert (Editor.Ada_Project_Index.Contains_Path
                (Index, "src\normalized_path.ads/"),
              "project index path containment should normalize separators and trailing slashes");
      Assert (Editor.Ada_Project_Index.Contains_Current
                (Index,
                 "src\normalized_path.ads/",
                 Buffer_Token => 77,
                 Buffer_Revision => 3,
                 Lifecycle_Generation => 9,
                 Analysis_Fingerprint => Fingerprint),
              "current-stamp containment should normalize path spelling");
      Assert (Editor.Ada_Project_Index.Has_Current_Match
                (Index,
                 "Normalized_Path",
                 "src\normalized_path.ads/",
                 Buffer_Token => 77,
                 Buffer_Revision => 3,
                 Lifecycle_Generation => 9,
                 Analysis_Fingerprint => Fingerprint),
              "current indexed symbol lookup should normalize path spelling");
   end Test_Project_Index_Current_And_Path_Containment_Normalizes_Path;



   procedure Test_Project_Index_Invalidates_Path_Subtree
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent_Subtree is" & ASCII.LF &
           "end Parent_Subtree;" & ASCII.LF,
           "parent_subtree.ads");
      Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Child_Subtree is" & ASCII.LF &
           "end Child_Subtree;" & ASCII.LF,
           "child_subtree.ads");
      Survivor_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Subtree_Survivor is" & ASCII.LF &
           "end Subtree_Survivor;" & ASCII.LF,
           "subtree_survivor.ads");
      Index : Editor.Ada_Project_Index.Index_State;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/renamed", Buffer_Token => 101, Buffer_Revision => 1,
         Lifecycle_Generation => 1, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/renamed/child.ads", Buffer_Token => 102, Buffer_Revision => 1,
         Lifecycle_Generation => 1, Analysis => Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/renamed_else.ads", Buffer_Token => 103, Buffer_Revision => 1,
         Lifecycle_Generation => 1, Analysis => Survivor_Analysis);

      Editor.Ada_Project_Index.Invalidate_Path_Subtree (Index, "src/renamed");

      Assert (Editor.Ada_Project_Index.File_Count (Index) = 1,
              "subtree invalidation should remove exact and descendant indexed paths only");
      Assert (not Editor.Ada_Project_Index.Has_Match (Index, "Parent_Subtree"),
              "exact old path should be removed after directory/file lifecycle mutation");
      Assert (not Editor.Ada_Project_Index.Has_Match (Index, "Child_Subtree"),
              "descendant path should be removed after directory rename/delete lifecycle mutation");
      Assert (Editor.Ada_Project_Index.Has_Match (Index, "Subtree_Survivor"),
              "same-prefix sibling paths must remain indexed");
   end Test_Project_Index_Invalidates_Path_Subtree;


   procedure Test_Project_Index_Unselected_Lookup_Rejects_Dotted_Leaf
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Index    : Editor.Ada_Project_Index.Index_State;
      Dotted_Id : Editor.Ada_Language_Model.Symbol_Id;
      Direct_Id : Editor.Ada_Language_Model.Symbol_Id;
      Leaf_Only : Editor.Ada_Project_Index.Index_Resolution_Result;
      Selected  : Editor.Ada_Project_Index.Index_Resolution_Result;
      Direct    : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Dotted_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Inner.Widget",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 12));

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/dotted_leaf.ads", Buffer_Token => 92,
         Buffer_Revision => 1, Lifecycle_Generation => 16,
         Analysis => Analysis);

      Leaf_Only := Editor.Ada_Project_Index.Resolve (Index, "Widget");
      Selected := Editor.Ada_Project_Index.Resolve (Index, "Inner.Widget");

      Assert (Dotted_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain the selected/dotted declaration name");
      Assert (Natural (Leaf_Only.Matches.Length) = 0,
              "project-index unselected lookup must not bind to selected-name leaves");
      Assert (Natural (Selected.Matches.Length) = 1,
              "project-index exact selected-name lookup should remain supported");

      Direct_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Widget",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 2, Start_Column => 1, End_Line => 2, End_Column => 6));
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/dotted_leaf.ads", Buffer_Token => 92,
         Buffer_Revision => 2, Lifecycle_Generation => 16,
         Analysis => Analysis);

      Direct := Editor.Ada_Project_Index.Resolve (Index, "Widget");
      Assert (Direct_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain a direct declaration with the same leaf");
      Assert (Natural (Direct.Matches.Length) = 1,
              "direct unselected declarations should still resolve project-wide");
   end Test_Project_Index_Unselected_Lookup_Rejects_Dotted_Leaf;



   procedure Test_Project_Index_Subprogram_Spec_Body_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Api is" & ASCII.LF &
           "   procedure Run (Count : Natural);" & ASCII.LF &
           "   function Make return Natural;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Api is" & ASCII.LF &
           "   procedure Run (Count : Natural) is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "   function Make return Natural is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      return 1;" & ASCII.LF &
           "   end Make;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Run_Res  : Editor.Ada_Project_Index.Index_Resolution_Result;
      Make_Res : Editor.Ada_Project_Index.Index_Resolution_Result;
      Saw_Run_Spec  : Boolean := False;
      Saw_Run_Body  : Boolean := False;
      Saw_Make_Spec : Boolean := False;
      Saw_Make_Body : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);

      Run_Res := Editor.Ada_Project_Index.Resolve (Index, "Run");
      if not Run_Res.Matches.Is_Empty then
         for I in Run_Res.Matches.First_Index .. Run_Res.Matches.Last_Index loop
            if Run_Res.Matches (I).Symbol.Kind = Editor.Ada_Language_Model.Symbol_Procedure then
               if Run_Res.Matches (I).Symbol.Flags.Is_Body then
                  Saw_Run_Body := True;
               else
                  Saw_Run_Spec := True;
               end if;
            end if;
         end loop;
      end if;

      Make_Res := Editor.Ada_Project_Index.Resolve (Index, "Make");
      if not Make_Res.Matches.Is_Empty then
         for I in Make_Res.Matches.First_Index .. Make_Res.Matches.Last_Index loop
            if Make_Res.Matches (I).Symbol.Kind = Editor.Ada_Language_Model.Symbol_Function then
               if Make_Res.Matches (I).Symbol.Flags.Is_Body then
                  Saw_Make_Body := True;
               else
                  Saw_Make_Spec := True;
               end if;
            end if;
         end loop;
      end if;

      Assert (Saw_Run_Spec and then Saw_Run_Body,
              "project index should retain procedure spec/body targets for Outline navigation");
      Assert (Saw_Make_Spec and then Saw_Make_Body,
              "project index should retain function spec/body targets for Outline navigation");
   end Test_Project_Index_Subprogram_Spec_Body_Targets;



   procedure Test_Project_Index_Subprogram_Targets_Retain_Profiles
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Api is" & ASCII.LF &
           "   procedure Run (Count : Natural);" & ASCII.LF &
           "   procedure Run (Name : String);" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Api is" & ASCII.LF &
           "   procedure Run (Name : String) is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "   procedure Run (Count : Natural) is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Run;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Res   : Editor.Ada_Project_Index.Index_Resolution_Result;
      Saw_Count_Spec : Boolean := False;
      Saw_Count_Body : Boolean := False;
      Saw_Name_Spec  : Boolean := False;
      Saw_Name_Body  : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);

      Res := Editor.Ada_Project_Index.Resolve (Index, "Run");
      if not Res.Matches.Is_Empty then
         for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
            declare
               Profile : constant String :=
                 To_String (Res.Matches (I).Symbol.Profile_Summary);
            begin
               if Res.Matches (I).Symbol.Kind = Editor.Ada_Language_Model.Symbol_Procedure then
                  if Profile = "(Count : Natural)" then
                     if Res.Matches (I).Symbol.Flags.Is_Body then
                        Saw_Count_Body := True;
                     else
                        Saw_Count_Spec := True;
                     end if;
                  elsif Profile = "(Name : String)" then
                     if Res.Matches (I).Symbol.Flags.Is_Body then
                        Saw_Name_Body := True;
                     else
                        Saw_Name_Spec := True;
                     end if;
                  end if;
               end if;
            end;
         end loop;
      end if;

      Assert (Saw_Count_Spec and then Saw_Count_Body,
              "project index should retain Count overload spec/body profile metadata");
      Assert (Saw_Name_Spec and then Saw_Name_Body,
              "project index should retain Name overload spec/body profile metadata");
   end Test_Project_Index_Subprogram_Targets_Retain_Profiles;



   procedure Test_Project_Index_Navigation_Candidates_Report_Ambiguity
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Body_Flags : Editor.Ada_Language_Model.Declaration_Flags := (others => False);
      Analysis_A : Editor.Ada_Language_Model.Analysis_Result;
      Analysis_B : Editor.Ada_Language_Model.Analysis_Result;
      Index      : Editor.Ada_Project_Index.Index_State;
      Result     : Editor.Ada_Project_Index.Navigation_Candidate_Result;
      A_Id       : Editor.Ada_Language_Model.Symbol_Id;
      B_Id       : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Body_Flags.Is_Body := True;
      A_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis_A,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 6, End_Column => 11),
         Profile_Summary => "(Item : Natural)",
         Flags => Body_Flags);
      B_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis_B,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 7, Start_Column => 4, End_Line => 10, End_Column => 11),
         Profile_Summary => "(Item : Natural)",
         Flags => Body_Flags);

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/a.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis_A);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/b.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis_B);

      Result := Editor.Ada_Project_Index.Resolve_Navigation_Candidates
        (Index,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         Want_Body       => True,
         Profile_Summary => "(Item : Natural)",
         Require_Profile => True);

      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain both ambiguous body candidates");
      Assert (Result.Status = Editor.Ada_Project_Index.Navigation_Target_Ambiguous,
              "candidate navigation should expose ambiguity to the UI layer");
      Assert (Natural (Result.Candidates.Length) = 2,
              "candidate navigation should retain both duplicate choices");
   end Test_Project_Index_Navigation_Candidates_Report_Ambiguity;



   procedure Test_Project_Index_Navigation_Candidate_Labels_Are_Presentable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Body_Flags : Editor.Ada_Language_Model.Declaration_Flags := (others => False);
      Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Index      : Editor.Ada_Project_Index.Index_State;
      Result     : Editor.Ada_Project_Index.Navigation_Candidate_Result;
      Id         : Editor.Ada_Language_Model.Symbol_Id;
      Label      : Unbounded_String;
      Detail     : Unbounded_String;
   begin
      Body_Flags.Is_Body := True;
      Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 12, Start_Column => 7, End_Line => 15, End_Column => 14),
         Profile_Summary => "(Item : Natural)",
         Flags => Body_Flags);

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/runner.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis);

      Result := Editor.Ada_Project_Index.Resolve_Navigation_Candidates
        (Index,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         Want_Body       => True,
         Profile_Summary => "(Item : Natural)",
         Require_Profile => True);

      Assert (Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain a callable body target");
      Assert (Result.Status = Editor.Ada_Project_Index.Navigation_Target_Unique,
              "label test should resolve one validated candidate");

      Label := To_Unbounded_String
        (Editor.Ada_Project_Index.Navigation_Candidate_Display_Label
           (Result.Candidates.First_Element));
      Detail := To_Unbounded_String
        (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
           (Result.Candidates.First_Element));

      Assert (Ada.Strings.Fixed.Index (To_String (Label), "src/runner.adb:12:7") > 0,
              "candidate label should include validated path and source position");
      Assert (Ada.Strings.Fixed.Index (To_String (Label), "procedure Run (Item : Natural)") > 0,
              "candidate label should include kind, name, and profile");
      Assert (Ada.Strings.Fixed.Index (To_String (Detail), "body") > 0,
              "candidate detail should preserve body/spec distinction for chooser rows");
   end Test_Project_Index_Navigation_Candidate_Labels_Are_Presentable;



   procedure Test_Project_Index_Unique_Navigation_Target_Rejects_Ambiguity
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Body_Flags : Editor.Ada_Language_Model.Declaration_Flags := (others => False);
      Analysis_A : Editor.Ada_Language_Model.Analysis_Result;
      Analysis_B : Editor.Ada_Language_Model.Analysis_Result;
      Index      : Editor.Ada_Project_Index.Index_State;
      Target     : Editor.Ada_Project_Index.Unique_Target_Result;
      A_Id       : Editor.Ada_Language_Model.Symbol_Id;
      B_Id       : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Body_Flags.Is_Body := True;
      A_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis_A,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 6, End_Column => 11),
         Profile_Summary => "(Item : Natural)",
         Flags => Body_Flags);
      B_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis_B,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 7, Start_Column => 4, End_Line => 10, End_Column => 11),
         Profile_Summary => "(Item : Natural)",
         Flags => Body_Flags);

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/a.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis_A);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/b.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis_B);

      Target := Editor.Ada_Project_Index.Resolve_Unique_Navigation_Target
        (Index,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         Want_Body       => True,
         Profile_Summary => "(Item : Natural)",
         Require_Profile => True);

      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain both duplicate body candidates");
      Assert (Target.Ambiguous,
              "unique navigation target resolution should report duplicate candidates");
      Assert (not Target.Available,
              "ambiguous project-index navigation must not pick the first candidate");
   end Test_Project_Index_Unique_Navigation_Target_Rejects_Ambiguity;



   procedure Test_Project_Index_Unique_Navigation_Target_Uses_Profile
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Body_Flags : Editor.Ada_Language_Model.Declaration_Flags := (others => False);
      Analysis_A : Editor.Ada_Language_Model.Analysis_Result;
      Analysis_B : Editor.Ada_Language_Model.Analysis_Result;
      Index      : Editor.Ada_Project_Index.Index_State;
      Target     : Editor.Ada_Project_Index.Unique_Target_Result;
      A_Id       : Editor.Ada_Language_Model.Symbol_Id;
      B_Id       : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Body_Flags.Is_Body := True;
      A_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis_A,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 6, End_Column => 11),
         Profile_Summary => "(Count : Natural)",
         Flags => Body_Flags);
      B_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis_B,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 7, Start_Column => 4, End_Line => 10, End_Column => 11),
         Profile_Summary => "(Name : String)",
         Flags => Body_Flags);

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/count.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis_A);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/name.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis_B);

      Target := Editor.Ada_Project_Index.Resolve_Unique_Navigation_Target
        (Index,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         Want_Body       => True,
         Profile_Summary => "(Count : Natural)",
         Require_Profile => True);

      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain both overload body candidates");
      Assert (Target.Available,
              "profile-specific unique navigation should resolve exactly one candidate");
      Assert (not Target.Ambiguous,
              "profile-specific unique navigation should not be ambiguous");
      Assert (To_String (Target.Target.Path) = "src/count.adb",
              "unique navigation target should preserve the profiled candidate path");
   end Test_Project_Index_Unique_Navigation_Target_Uses_Profile;



   procedure Test_Project_Index_Unique_Navigation_Target_Rejects_Overflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Body_Flags : Editor.Ada_Language_Model.Declaration_Flags := (others => False);
      Target_Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Overflow_Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Index : Editor.Ada_Project_Index.Index_State;
      Target : Editor.Ada_Project_Index.Unique_Target_Result;
      Target_Id : Editor.Ada_Language_Model.Symbol_Id;
      Added : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Body_Flags.Is_Body := True;
      Target_Id := Editor.Ada_Language_Model.Add_Symbol
        (Target_Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 6, End_Column => 11),
         Profile_Summary => "(Item : Natural)",
         Flags => Body_Flags);

      for I in 1 .. Editor.Ada_Language_Model.Max_Analysis_Symbols + 1 loop
         Added := Editor.Ada_Language_Model.Add_Symbol
           (Overflow_Analysis,
            "Overflow_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Both),
            Editor.Ada_Language_Model.Symbol_Object,
            (Start_Line => Positive (I), Start_Column => 1,
             End_Line => Positive (I), End_Column => 10));
      end loop;

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/run.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Target_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/overflow.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Overflow_Analysis);

      Target := Editor.Ada_Project_Index.Resolve_Unique_Navigation_Target
        (Index,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         Want_Body       => True,
         Profile_Summary => "(Item : Natural)",
         Require_Profile => True);

      Assert (Target_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain the apparent navigation target");
      Assert (Added = Editor.Ada_Language_Model.No_Symbol,
              "test setup should overflow one indexed analysis");
      Assert (Target.Overflow,
              "unique navigation target resolution should expose index or analysis overflow");
      Assert (not Target.Available,
              "overflowed project indexes must not expose apparent unique navigation targets");
      Assert (not Target.Ambiguous,
              "overflow degradation is not duplicate-candidate ambiguity");
   end Test_Project_Index_Unique_Navigation_Target_Rejects_Overflow;



   procedure Test_Project_Index_Target_Key_Revalidation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Body_Flags : Editor.Ada_Language_Model.Declaration_Flags := (others => False);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Index : Editor.Ada_Project_Index.Index_State;
      Target : Editor.Ada_Project_Index.Unique_Target_Result;
      Target_Id : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Body_Flags.Is_Body := True;
      Target_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 6, End_Column => 11),
         Profile_Summary => "(Item : Natural)",
         Flags => Body_Flags);

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/run.adb", Buffer_Token => 42, Buffer_Revision => 7,
         Lifecycle_Generation => 11, Analysis => Analysis);

      Target := Editor.Ada_Project_Index.Resolve_Unique_Navigation_Target
        (Index,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         Want_Body       => True,
         Profile_Summary => "(Item : Natural)",
         Require_Profile => True);

      Assert (Target_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Target.Available,
              "test setup should retain a unique open-buffer navigation target");
      Assert (Editor.Ada_Project_Index.Contains_Key (Index, Target.Target.Key),
              "project index should revalidate the exact retained target key");
      Assert
        (Editor.Ada_Project_Index.Contains_Open_Buffer_Key
           (Index, Target.Target.Key, "src/run.adb", 42, 7, 11),
         "open-buffer target key should match its current buffer stamp");
      Assert
        (Editor.Ada_Project_Index.Contains_Open_Buffer_Key
           (Index, Target.Target.Key, "src\\run.adb", 42, 7, 11),
         "open-buffer target key should normalize path spellings during revalidation");
      Assert
        (not Editor.Ada_Project_Index.Contains_Open_Buffer_Key
           (Index, Target.Target.Key, "src/run.adb", 42, 8, 11),
         "edited buffer revisions must stale an indexed navigation target key");

      Editor.Ada_Project_Index.Clear (Index);
      Assert (not Editor.Ada_Project_Index.Contains_Key (Index, Target.Target.Key),
              "clearing the index must stale previously projected navigation keys");
   end Test_Project_Index_Target_Key_Revalidation;




   procedure Test_Project_Index_Cross_File_Unit_Relationship_Table
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Child is" & ASCII.LF &
           "   procedure Compute;" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Parent.Child is" & ASCII.LF &
           "   procedure Compute is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Compute;" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.adb");
      Separate_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Parent.Child)" & ASCII.LF &
           "procedure Compute is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Compute;" & ASCII.LF,
           "compute.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Spec_Units : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Body_Units : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Separate_Units : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Spec_Target : Editor.Ada_Project_Index.Unique_Target_Result;
      Body_Target : Editor.Ada_Project_Index.Unique_Target_Result;
      From_Spec_To_Body : Editor.Ada_Project_Index.Unique_Target_Result;
      From_Body_To_Spec : Editor.Ada_Project_Index.Unique_Target_Result;
      Separate_Parent : Editor.Ada_Project_Index.Unique_Target_Result;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/compute.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Analysis);

      Spec_Units := Editor.Ada_Project_Index.Resolve_Unit
        (Index, "parent.child", Editor.Ada_Project_Index.Unit_Package_Spec);
      Body_Units := Editor.Ada_Project_Index.Resolve_Unit
        (Index, "Parent.Child", Editor.Ada_Project_Index.Unit_Package_Body);
      Separate_Units := Editor.Ada_Project_Index.Resolve_Unit
        (Index, "Parent.Child", Editor.Ada_Project_Index.Unit_Separate_Body);

      Assert (Editor.Ada_Project_Index.Unit_Count (Index) >= 3,
              "project index should retain first-class Ada unit rows");
      Assert (Natural (Spec_Units.Matches.Length) = 1,
              "unit table should resolve the package spec by normalized Ada unit name");
      Assert (Natural (Body_Units.Matches.Length) = 1,
              "unit table should resolve the package body by normalized Ada unit name");
      Assert (Natural (Separate_Units.Matches.Length) = 1,
              "unit table should resolve separate bodies by parent Ada unit name");

      Spec_Target := Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
        (Index, "Parent.Child", Editor.Ada_Project_Index.Unit_Package_Spec);
      Body_Target := Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
        (Index, "Parent.Child", Editor.Ada_Project_Index.Unit_Package_Body);

      Assert (Spec_Target.Available
              and then To_String (Spec_Target.Target.Path) = "src/parent-child.ads",
              "unique unit-target lookup should return the indexed package spec file");
      Assert (Body_Target.Available
              and then To_String (Body_Target.Target.Path) = "src/parent-child.adb",
              "unique unit-target lookup should return the indexed package body file");

      From_Spec_To_Body := Editor.Ada_Project_Index.Resolve_Related_Unit_Target
        (Index, Spec_Target.Target, Want_Body => True);
      From_Body_To_Spec := Editor.Ada_Project_Index.Resolve_Related_Unit_Target
        (Index, Body_Target.Target, Want_Body => False);

      Assert (From_Spec_To_Body.Available
              and then To_String (From_Spec_To_Body.Target.Path) = "src/parent-child.adb",
              "unit relationships should navigate from spec to matching body");
      Assert (From_Body_To_Spec.Available
              and then To_String (From_Body_To_Spec.Target.Path) = "src/parent-child.ads",
              "unit relationships should navigate from body to matching spec");

      Separate_Parent := Editor.Ada_Project_Index.Resolve_Separate_Parent_Target
        (Index,
         (Path   => Separate_Units.Matches.First_Element.Path,
          Key    => Separate_Units.Matches.First_Element.Key,
          Symbol => Separate_Units.Matches.First_Element.Symbol));

      Assert (Separate_Parent.Available
              and then To_String (Separate_Parent.Target.Path) = "src/parent-child.ads",
              "unit relationships should resolve a separate body to its parent unit declaration");
   end Test_Project_Index_Cross_File_Unit_Relationship_Table;



   procedure Test_Project_Index_Unit_Family_Lists_Validated_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Child is" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Parent.Child is" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.adb");
      Separate_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Parent.Child)" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF,
           "worker.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Spec_Target : Editor.Ada_Project_Index.Unique_Target_Result;
      Family : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Body_Only : Editor.Ada_Project_Index.Unit_Resolution_Result;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/worker.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Analysis);

      Spec_Target := Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
        (Index, "Parent.Child", Editor.Ada_Project_Index.Unit_Package_Spec);

      Assert (Spec_Target.Available,
              "unit-family lookup requires an indexed starting unit target");

      Family := Editor.Ada_Project_Index.Resolve_Unit_Family
        (Index, Spec_Target.Target);
      Body_Only := Editor.Ada_Project_Index.Resolve_Unit_Family
        (Index, Spec_Target.Target, Editor.Ada_Project_Index.Unit_Package_Body);

      Assert (not Family.Overflow,
              "unit-family lookup should not overflow for a small validated unit family");
      Assert (Natural (Family.Matches.Length) = 3,
              "unit-family lookup should list spec, body, and separate rows for one unit identity");
      Assert (Natural (Body_Only.Matches.Length) = 1
              and then To_String (Body_Only.Matches.First_Element.Path) = "src/parent-child.adb",
              "unit-family lookup should support role-filtered body targets");
   end Test_Project_Index_Unit_Family_Lists_Validated_Targets;



   procedure Test_Project_Index_Unit_Table_Excludes_Nested_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Outer is" & ASCII.LF &
           "   package Inner is" & ASCII.LF &
           "      procedure Local;" & ASCII.LF &
           "   end Inner;" & ASCII.LF &
           "end Outer;" & ASCII.LF,
           "outer.ads");
      Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Outer.Child is" & ASCII.LF &
           "end Outer.Child;" & ASCII.LF,
           "outer-child.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Outer_Units : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Nested_Units : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Local_Units : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Child_Units : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Local_Symbols : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/outer.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/outer-child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Child_Analysis);

      Outer_Units := Editor.Ada_Project_Index.Resolve_Unit
        (Index, "Outer", Editor.Ada_Project_Index.Unit_Package_Spec);
      Nested_Units := Editor.Ada_Project_Index.Resolve_Unit
        (Index, "Outer.Inner", Editor.Ada_Project_Index.Unit_Package_Spec);
      Local_Units := Editor.Ada_Project_Index.Resolve_Unit
        (Index, "Outer.Inner.Local", Editor.Ada_Project_Index.Unit_Subprogram_Spec);
      Child_Units := Editor.Ada_Project_Index.Resolve_Unit
        (Index, "Outer.Child", Editor.Ada_Project_Index.Unit_Package_Spec);
      Local_Symbols := Editor.Ada_Project_Index.Resolve
        (Index, "Outer.Inner.Local");

      Assert (Natural (Outer_Units.Matches.Length) = 1,
              "library package unit should remain indexed");
      Assert (Natural (Child_Units.Matches.Length) = 1,
              "dotted library child package unit should remain indexed");
      Assert (Natural (Nested_Units.Matches.Length) = 0,
              "nested package declarations must not become cross-file Ada unit rows");
      Assert (Natural (Local_Units.Matches.Length) = 0,
              "nested subprogram declarations must not become cross-file Ada unit rows");
      Assert (Natural (Local_Symbols.Matches.Length) = 1,
              "nested declarations should remain available through ordinary symbol lookup");
   end Test_Project_Index_Unit_Table_Excludes_Nested_Declarations;




   procedure Test_Project_Index_Cyclic_Parent_Chain_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Index    : Editor.Ada_Project_Index.Index_State;
      A_Id     : Editor.Ada_Language_Model.Symbol_Id;
      B_Id     : Editor.Ada_Language_Model.Symbol_Id;
      W_Id     : Editor.Ada_Language_Model.Symbol_Id;
      Dotted   : Editor.Ada_Project_Index.Index_Resolution_Result;
      Local    : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      A_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "A",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1),
         Parent_Symbol => 2);
      B_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "B",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 2, Start_Column => 1, End_Line => 2, End_Column => 1),
         Parent_Symbol => A_Id);
      W_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Widget",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 10),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (A_Id),
         Parent_Symbol => A_Id);

      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then W_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain a malformed cyclic parent chain");

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/cyclic_parent.ads", Buffer_Token => 91,
         Buffer_Revision => 1, Lifecycle_Generation => 15,
         Analysis => Analysis);

      Dotted := Editor.Ada_Project_Index.Resolve (Index, "A.Widget");
      Local := Editor.Ada_Project_Index.Resolve (Index, "Widget");

      Assert (Natural (Dotted.Matches.Length) = 0,
              "cyclic parent metadata must not fabricate dotted project-index targets");
      Assert (Natural (Local.Matches.Length) = 1,
              "cyclic parent metadata should still allow safe local-name lookup");
   end Test_Project_Index_Cyclic_Parent_Chain_Degrades;



   procedure Test_Project_Index_Non_Owner_Parent_Does_Not_Qualify_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Index    : Editor.Ada_Project_Index.Index_State;
      Obj_Id   : Editor.Ada_Language_Model.Symbol_Id;
      Bad_Id   : Editor.Ada_Language_Model.Symbol_Id;
      Pkg_Id   : Editor.Ada_Language_Model.Symbol_Id;
      Good_Id  : Editor.Ada_Language_Model.Symbol_Id;
      Bad_Selected  : Editor.Ada_Project_Index.Index_Resolution_Result;
      Bad_Local     : Editor.Ada_Project_Index.Index_Resolution_Result;
      Good_Selected : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Obj_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Obj",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 3));
      Bad_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Widget",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 10),
         Parent_Symbol => Obj_Id);
      Pkg_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Pkg",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 3, Start_Column => 1, End_Line => 3, End_Column => 3));
      Good_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Gadget",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 9),
         Parent_Symbol => Pkg_Id);

      Assert (Obj_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Bad_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Pkg_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Good_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain malformed and valid parent chains");

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/non_owner_parent.ads", Buffer_Token => 93,
         Buffer_Revision => 1, Lifecycle_Generation => 17,
         Analysis => Analysis);

      Bad_Selected := Editor.Ada_Project_Index.Resolve (Index, "Obj.Widget");
      Bad_Local := Editor.Ada_Project_Index.Resolve (Index, "Widget");
      Good_Selected := Editor.Ada_Project_Index.Resolve (Index, "Pkg.Gadget");

      Assert (Natural (Bad_Selected.Matches.Length) = 0,
              "project index must not qualify selected names through non-owner parent symbols");
      Assert (Natural (Bad_Local.Matches.Length) = 1,
              "non-owner parent metadata should still allow safe local-name lookup");
      Assert (Natural (Good_Selected.Matches.Length) = 1,
              "declaration-owning package parents should still qualify selected names");
   end Test_Project_Index_Non_Owner_Parent_Does_Not_Qualify_Name;



   procedure Test_Project_Index_Current_Stamp_Rejection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Stamp is" & ASCII.LF & "end Stamp;" & ASCII.LF,
           "stamp.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      FP : constant Natural := Editor.Ada_Language_Model.Fingerprint (Analysis);
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/stamp.ads", Buffer_Token => 21, Buffer_Revision => 7,
         Lifecycle_Generation => 3, Analysis => Analysis);
      Assert (Editor.Ada_Project_Index.Contains_Current
                (Index, "src/stamp.ads", 21, 7, 3, FP),
              "project index should validate current path/token/revision/lifecycle/fingerprint stamps");
      Assert (not Editor.Ada_Project_Index.Contains_Current
                (Index, "src/stamp.ads", 21, 8, 3, FP),
              "project index should reject stale buffer revisions");
      Assert (not Editor.Ada_Project_Index.Contains_Current
                (Index, "src/stamp.ads", 21, 7, 4, FP),
              "project index should reject stale lifecycle generations");
      Editor.Ada_Project_Index.Invalidate_Lifecycle (Index, 3);
      Assert (Editor.Ada_Project_Index.File_Count (Index) = 0,
              "lifecycle invalidation should clear indexed analyses from a closed/switched project generation");
   end Test_Project_Index_Current_Stamp_Rejection;


   procedure Test_Project_Index_Lifecycle_Invalidation_Removes_All_Matching_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      First_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package First_Lifecycle is" & ASCII.LF &
           "end First_Lifecycle;" & ASCII.LF,
           "first_lifecycle.ads");
      Second_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Second_Lifecycle is" & ASCII.LF &
           "end Second_Lifecycle;" & ASCII.LF,
           "second_lifecycle.ads");
      Survivor_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Survivor_Lifecycle is" & ASCII.LF &
           "end Survivor_Lifecycle;" & ASCII.LF,
           "survivor_lifecycle.ads");
      Index : Editor.Ada_Project_Index.Index_State;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/first_lifecycle.ads", Buffer_Token => 61, Buffer_Revision => 1,
         Lifecycle_Generation => 12, Analysis => First_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/second_lifecycle.ads", Buffer_Token => 62, Buffer_Revision => 1,
         Lifecycle_Generation => 12, Analysis => Second_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/survivor_lifecycle.ads", Buffer_Token => 63, Buffer_Revision => 1,
         Lifecycle_Generation => 13, Analysis => Survivor_Analysis);

      Assert (Editor.Ada_Project_Index.File_Count (Index) = 3,
              "test setup should index two stale lifecycle files and one survivor");

      Editor.Ada_Project_Index.Invalidate_Lifecycle (Index, 12);

      Assert (Editor.Ada_Project_Index.File_Count (Index) = 1,
              "lifecycle invalidation should delete all matching files without double-deleting adjacent entries");
      Assert (not Editor.Ada_Project_Index.Has_Match (Index, "First_Lifecycle"),
              "first stale lifecycle file should be removed");
      Assert (not Editor.Ada_Project_Index.Has_Match (Index, "Second_Lifecycle"),
              "second stale lifecycle file should be removed");
      Assert (Editor.Ada_Project_Index.Has_Match (Index, "Survivor_Lifecycle"),
              "different lifecycle generations should remain indexed");
   end Test_Project_Index_Lifecycle_Invalidation_Removes_All_Matching_Files;


   procedure Test_Project_Index_Current_Resolve_Filters_Stale_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Current_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Current_File is" & ASCII.LF &
           "   type Live_Type is private;" & ASCII.LF &
           "end Current_File;" & ASCII.LF,
           "current_file.ads");
      Other_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Other_File is" & ASCII.LF &
           "   type Live_Type is private;" & ASCII.LF &
           "end Other_File;" & ASCII.LF,
           "other_file.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Current_FP : constant Natural :=
        Editor.Ada_Language_Model.Fingerprint (Current_Analysis);
      All_Matches : Editor.Ada_Project_Index.Index_Resolution_Result;
      Current_Matches : Editor.Ada_Project_Index.Index_Resolution_Result;
      Stale_Matches : Editor.Ada_Project_Index.Index_Resolution_Result;
      Current_First : Editor.Ada_Project_Index.Indexed_Symbol;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/current_file.ads", Buffer_Token => 31,
         Buffer_Revision => 4, Lifecycle_Generation => 9,
         Analysis => Current_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/other_file.ads", Buffer_Token => 32,
         Buffer_Revision => 1, Lifecycle_Generation => 9,
         Analysis => Other_Analysis);

      All_Matches := Editor.Ada_Project_Index.Resolve (Index, "Live_Type");
      Current_Matches := Editor.Ada_Project_Index.Resolve_Current
        (Index, "Live_Type", "src/current_file.ads", 31, 4, 9, Current_FP);
      Stale_Matches := Editor.Ada_Project_Index.Resolve_Current
        (Index, "Live_Type", "src/current_file.ads", 31, 5, 9, Current_FP);
      Current_First := Editor.Ada_Project_Index.First_Current_Match
        (Index, "Live_Type", "src/current_file.ads", 31, 4, 9, Current_FP);

      Assert (Natural (All_Matches.Matches.Length) = 2,
              "ordinary index resolution may return all same-name project symbols");
      Assert (Natural (Current_Matches.Matches.Length) = 1,
              "current-stamped index resolution should filter to the validated path/token/revision/lifecycle/fingerprint");
      Assert (To_String (Current_Matches.Matches.First_Element.Path) = "src/current_file.ads",
              "current-stamped index resolution should retain the validated target path");
      Assert (Natural (Stale_Matches.Matches.Length) = 0,
              "current-stamped index resolution should reject stale revisions before navigation uses the target");
      Assert (To_String (Current_First.Path) = "src/current_file.ads",
              "First_Current_Match should return the validated current target");
      Assert (Editor.Ada_Project_Index.Has_Current_Match
                (Index, "Live_Type", "src/current_file.ads", 31, 4, 9, Current_FP),
              "Has_Current_Match should report validated current targets");
      Assert (not Editor.Ada_Project_Index.Has_Current_Match
                (Index, "Live_Type", "src/current_file.ads", 31, 4, 10, Current_FP),
              "Has_Current_Match should reject stale lifecycle generations");
   end Test_Project_Index_Current_Resolve_Filters_Stale_Targets;




   procedure Test_Project_Index_Propagates_Analysis_Overflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Index    : Editor.Ada_Project_Index.Index_State;
      Ignored  : Editor.Ada_Language_Model.Symbol_Id;
      All_Matches : Editor.Ada_Project_Index.Index_Resolution_Result;
      Current_Matches : Editor.Ada_Project_Index.Index_Resolution_Result;
      FP : Natural;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Max_Analysis_Symbols + 1 loop
         Ignored := Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            "Overflow_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Left),
            Editor.Ada_Language_Model.Symbol_Object,
            (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1));
      end loop;

      Assert (Editor.Ada_Language_Model.Overflowed (Analysis),
              "test setup should create an overflowed bounded analysis result");

      FP := Editor.Ada_Language_Model.Fingerprint (Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/overflow.ads", Buffer_Token => 41, Buffer_Revision => 2,
         Lifecycle_Generation => 5, Analysis => Analysis);

      All_Matches := Editor.Ada_Project_Index.Resolve (Index, "Overflow_1");
      Current_Matches := Editor.Ada_Project_Index.Resolve_Current
        (Index, "Overflow_1", "src/overflow.ads", 41, 2, 5, FP);

      Assert (All_Matches.Overflow,
              "project index resolution must propagate analysis overflow so semantic callers can degrade safely");
      Assert (Current_Matches.Overflow,
              "current-stamped project index resolution must propagate analysis overflow too");
      Assert (Natural (All_Matches.Matches.Length) = 1
              and then Natural (Current_Matches.Matches.Length) = 1,
              "overflow reporting must not discard deterministic in-budget matches");
      Assert (Ignored = Editor.Ada_Language_Model.No_Symbol,
              "the symbol beyond the bounded analysis budget should be rejected deterministically");
   end Test_Project_Index_Propagates_Analysis_Overflow;


   procedure Test_Project_Index_Overflowed_Includes_Analysis_Overflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Index    : Editor.Ada_Project_Index.Index_State;
      Ignored  : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Assert (not Editor.Ada_Project_Index.Overflowed (Index),
              "empty project index should not report overflow");

      for I in 1 .. Editor.Ada_Language_Model.Max_Analysis_Symbols + 1 loop
         Ignored := Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            "Indexed_Overflow_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Left),
            Editor.Ada_Language_Model.Symbol_Object,
            (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1));
      end loop;

      Assert (Ignored = Editor.Ada_Language_Model.No_Symbol,
              "test setup should hit the bounded per-analysis symbol limit");
      Assert (Editor.Ada_Language_Model.Overflowed (Analysis),
              "test setup should create an overflowed analysis result");

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/indexed_overflow.ads", Buffer_Token => 71,
         Buffer_Revision => 1, Lifecycle_Generation => 14,
         Analysis => Analysis);

      Assert (Editor.Ada_Project_Index.File_Count (Index) = 1,
              "test setup should keep the index file table itself in budget");
      Assert (Editor.Ada_Project_Index.Overflowed (Index),
              "project index aggregate overflow should include per-file analysis overflow");

      Editor.Ada_Project_Index.Clear (Index);
      Assert (not Editor.Ada_Project_Index.Overflowed (Index),
              "clearing the project index should clear aggregate overflow state");
   end Test_Project_Index_Overflowed_Includes_Analysis_Overflow;



   procedure Test_Project_Index_Fingerprint_Includes_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Indexed is" & ASCII.LF & "end Indexed;" & ASCII.LF,
           "indexed.ads");
      Left_Index  : Editor.Ada_Project_Index.Index_State;
      Right_Index : Editor.Ada_Project_Index.Index_State;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Left_Index, "src/left/indexed.ads", Buffer_Token => 81,
         Buffer_Revision => 3, Lifecycle_Generation => 9,
         Analysis => Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Right_Index, "src/right/indexed.ads", Buffer_Token => 81,
         Buffer_Revision => 3, Lifecycle_Generation => 9,
         Analysis => Analysis);

      Assert (Editor.Ada_Project_Index.File_Count (Left_Index) = 1
              and then Editor.Ada_Project_Index.File_Count (Right_Index) = 1,
              "test setup should index one current file in each project index");
      Assert (Editor.Ada_Project_Index.Fingerprint (Left_Index) /=
              Editor.Ada_Project_Index.Fingerprint (Right_Index),
              "project index fingerprint must include the indexed path, not only shared buffer/revision/lifecycle/analysis stamps");
   end Test_Project_Index_Fingerprint_Includes_Path;



   procedure Test_Project_Index_Fingerprint_Includes_Index_Overflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Index : Editor.Ada_Project_Index.Index_State;
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Ignored : Editor.Ada_Language_Model.Symbol_Id;
      Before_Overflow : Natural;
      After_Overflow  : Natural;
   begin
      Ignored := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Indexed_Symbol",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1));
      Assert (Ignored /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should create one reusable analysis symbol");

      for I in 1 .. Editor.Ada_Project_Index.Max_Index_Files loop
         Editor.Ada_Project_Index.Put_Analysis
           (Index,
            "src/fingerprint_overflow_" &
              Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Left) & ".ads",
            Buffer_Token => I,
            Buffer_Revision => 1,
            Lifecycle_Generation => 1,
            Analysis => Analysis);
      end loop;

      Assert (Editor.Ada_Project_Index.File_Count (Index) =
              Editor.Ada_Project_Index.Max_Index_Files,
              "test setup should fill the bounded project index exactly");
      Assert (not Editor.Ada_Project_Index.Overflowed (Index),
              "an exactly full index is still in budget before the rejected insert");
      Before_Overflow := Editor.Ada_Project_Index.Fingerprint (Index);

      Editor.Ada_Project_Index.Put_Analysis
        (Index,
         "src/fingerprint_overflow_extra.ads",
         Buffer_Token => Editor.Ada_Project_Index.Max_Index_Files + 1,
         Buffer_Revision => 1,
         Lifecycle_Generation => 1,
         Analysis => Analysis);

      After_Overflow := Editor.Ada_Project_Index.Fingerprint (Index);

      Assert (Editor.Ada_Project_Index.File_Count (Index) =
              Editor.Ada_Project_Index.Max_Index_Files,
              "overflow insertion must not append beyond the file-table budget");
      Assert (Editor.Ada_Project_Index.Overflowed (Index),
              "overflow insertion should mark the project index conservative");
      Assert (Before_Overflow /= After_Overflow,
              "project index fingerprint must change when the file-table overflow state changes");
   end Test_Project_Index_Fingerprint_Includes_Index_Overflow;




   procedure Test_Project_Index_Resolves_Cross_File_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Source : constant String :=
        "package Shared is" & ASCII.LF &
        "   type Widget is private;" & ASCII.LF &
        "   procedure Use_Widget (Item : Widget);" & ASCII.LF &
        "end Shared;" & ASCII.LF;
      Body_Source : constant String :=
        "package body Shared is" & ASCII.LF &
        "   procedure Use_Widget (Item : Widget) is null;" & ASCII.LF &
        "end Shared;" & ASCII.LF;
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Spec_Source, "shared.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Body_Source, "shared.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Widget_Result : Editor.Ada_Project_Index.Index_Resolution_Result;
      Use_Result    : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/shared.ads", 1, 10, 100, Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/shared.adb", 2, 20, 100, Body_Analysis);

      Widget_Result := Editor.Ada_Project_Index.Resolve (Index, "Widget");
      Use_Result := Editor.Ada_Project_Index.Resolve (Index, "Use_Widget");

      Assert (not Widget_Result.Matches.Is_Empty,
              "project index should resolve symbols across indexed files");
      Assert (To_String (Widget_Result.Matches.First_Element.Path) = "src/shared.ads",
              "project index matches should retain the indexed source path");
      Assert (Natural (Use_Result.Matches.Length) >= 2,
              "project index should retain same-name spec/body overload-like matches across files");
      Assert (Editor.Ada_Project_Index.Has_Match (Index, "Shared.Widget"),
              "project index lookup should support qualified names by exact or leaf match");
      Assert (not Editor.Ada_Project_Index.Has_Match (Index, "Missing"),
              "project index lookup should not invent missing symbols");
   end Test_Project_Index_Resolves_Cross_File_Symbols;



   procedure Test_Project_Index_Qualified_Lookup_Does_Not_Leaf_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Shared_Source : constant String :=
        "package Shared is" & ASCII.LF &
        "   type Widget is private;" & ASCII.LF &
        "end Shared;" & ASCII.LF;
      Other_Source : constant String :=
        "package Other is" & ASCII.LF &
        "   type Widget is private;" & ASCII.LF &
        "end Other;" & ASCII.LF;
      Shared_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Shared_Source, "shared.ads");
      Other_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Other_Source, "other.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Shared_Widget : Editor.Ada_Project_Index.Index_Resolution_Result;
      Other_Widget  : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/shared.ads", 11, 101, 1000, Shared_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/other.ads", 12, 102, 1000, Other_Analysis);

      Shared_Widget := Editor.Ada_Project_Index.Resolve (Index, "Shared.Widget");
      Other_Widget := Editor.Ada_Project_Index.Resolve (Index, "Other.Widget");

      Assert (Natural (Shared_Widget.Matches.Length) = 1,
              "qualified index lookup must not match every same-leaf symbol");
      Assert (To_String (Shared_Widget.Matches.First_Element.Path) = "src/shared.ads",
              "qualified index lookup should bind Shared.Widget to Shared's file");
      Assert (Natural (Other_Widget.Matches.Length) = 1,
              "other qualified index lookup should also remain exact");
      Assert (To_String (Other_Widget.Matches.First_Element.Path) = "src/other.ads",
              "qualified index lookup should bind Other.Widget to Other's file");
   end Test_Project_Index_Qualified_Lookup_Does_Not_Leaf_Match;


   overriding function Name (T : Project_Index_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Project_Index");
   end Name;

   overriding procedure Register_Tests (T : in out Project_Index_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Project_Index_Invalidates_Buffer_And_Path'Access, Name => "project language index invalidates stale path and buffer targets");
      Add_Test (Routine => Test_Project_Index_Current_And_Path_Containment_Normalizes_Path'Access, Name => "project language index normalizes current path containment and lookup");
      Add_Test (Routine => Test_Project_Index_Invalidates_Path_Subtree'Access, Name => "project language index invalidates exact and descendant file-tree paths");
      Add_Test (Routine => Test_Project_Index_Unselected_Lookup_Rejects_Dotted_Leaf'Access, Name => "project index unselected lookup rejects selected-name leaves");
      Add_Test (Routine => Test_Project_Index_Subprogram_Spec_Body_Targets'Access, Name => "project index retains subprogram spec/body targets");
      Add_Test (Routine => Test_Project_Index_Subprogram_Targets_Retain_Profiles'Access, Name => "project index retains subprogram overload profile metadata for navigation");
      Add_Test (Routine => Test_Project_Index_Navigation_Candidates_Report_Ambiguity'Access, Name => "project index exposes ambiguous navigation candidates for UI selection");
      Add_Test (Routine => Test_Project_Index_Navigation_Candidate_Labels_Are_Presentable'Access, Name => "project index formats navigation candidates for ambiguity chooser rows");
      Add_Test (Routine => Test_Project_Index_Unique_Navigation_Target_Rejects_Ambiguity'Access, Name => "project index unique navigation rejects ambiguous duplicate targets");
      Add_Test (Routine => Test_Project_Index_Unique_Navigation_Target_Uses_Profile'Access, Name => "project index unique navigation uses retained profiles");
      Add_Test (Routine => Test_Project_Index_Unique_Navigation_Target_Rejects_Overflow'Access, Name => "project index unique navigation rejects overflowed indexes");
      Add_Test (Routine => Test_Project_Index_Target_Key_Revalidation'Access, Name => "project index navigation target keys are revalidated before use");
      Add_Test (Routine => Test_Project_Index_Cross_File_Unit_Relationship_Table'Access, Name => "project index retains cross-file Ada unit relationships");
      Add_Test (Routine => Test_Project_Index_Unit_Family_Lists_Validated_Targets'Access, Name => "project index lists validated spec body and separate unit-family targets");
      Add_Test (Routine => Test_Project_Index_Unit_Table_Excludes_Nested_Declarations'Access, Name => "project index unit table excludes nested declarations from library unit rows");
      Add_Test (Routine => Test_Project_Index_Cyclic_Parent_Chain_Degrades'Access, Name => "project index bounded qualified-name lookup rejects cyclic parent chains");
      Add_Test (Routine => Test_Project_Index_Non_Owner_Parent_Does_Not_Qualify_Name'Access, Name => "project index qualified-name lookup rejects non-owner parent prefixes");
      Add_Test (Routine => Test_Project_Index_Current_Stamp_Rejection'Access, Name => "project language index rejects stale ownership stamps");
      Add_Test (Routine => Test_Project_Index_Lifecycle_Invalidation_Removes_All_Matching_Files'Access, Name => "project language index lifecycle invalidation removes all matching files");
      Add_Test (Routine => Test_Project_Index_Current_Resolve_Filters_Stale_Targets'Access, Name => "project language index resolves only validated current targets when requested");
      Add_Test (Routine => Test_Project_Index_Propagates_Analysis_Overflow'Access, Name => "project language index propagates bounded analysis overflow");
      Add_Test (Routine => Test_Project_Index_Overflowed_Includes_Analysis_Overflow'Access, Name => "project index aggregate overflow includes analysis overflow");
      Add_Test (Routine => Test_Project_Index_Fingerprint_Includes_Path'Access, Name => "project language index fingerprints include indexed paths");
      Add_Test (Routine => Test_Project_Index_Fingerprint_Includes_Index_Overflow'Access, Name => "project language index fingerprints include file-table overflow state");
      Add_Test (Routine => Test_Project_Index_Resolves_Cross_File_Symbols'Access, Name => "project language index resolves symbols across indexed files");
      Add_Test (Routine => Test_Project_Index_Qualified_Lookup_Does_Not_Leaf_Match'Access, Name => "project language index qualified lookup rejects leaf-only matches");
   end Register_Tests;

end Editor.Syntax_Semantics.Project_Index_Tests;
