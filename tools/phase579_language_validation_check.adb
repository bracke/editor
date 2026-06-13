with Editor_Tool_Common; use Editor_Tool_Common;

procedure Phase579_Language_Validation_Check is
   Tool : constant String := "phase579_language_validation_check";
   Tool_Failed : Boolean := False;

   Language_Model_Spec : constant String := "src/core/editor-ada_language_model.ads";
   Language_Model_Body : constant String := "src/core/editor-ada_language_model.adb";
   Syntax_Tree_Spec    : constant String := "src/core/editor-ada_syntax_tree.ads";
   Syntax_Tree_Body    : constant String := "src/core/editor-ada_syntax_tree.adb";
   Parser_Spec         : constant String := "src/core/editor-ada_declaration_parser.ads";
   Parser_Body         : constant String := "src/core/editor-ada_declaration_parser.adb";
   Token_Cursor_Spec   : constant String := "src/core/editor-ada_token_cursor.ads";
   Token_Cursor_Body   : constant String := "src/core/editor-ada_token_cursor.adb";
   Resolver_Spec       : constant String := "src/core/editor-ada_symbol_resolver.ads";
   Resolver_Body       : constant String := "src/core/editor-ada_symbol_resolver.adb";
   Index_Spec          : constant String := "src/core/editor-ada_project_index.ads";
   Index_Body          : constant String := "src/core/editor-ada_project_index.adb";
   Syntax_Tests        : constant String := "tests/src/editor-syntax_semantics-tests.adb";
   Outline_Tests       : constant String := "tests/src/editor-outline-tests.adb";
   Outline_Source      : constant String := "src/core/editor-outline_extractor.adb";
   Semantics_Source    : constant String := "src/core/editor-syntax_semantics.adb";
   Validation_Check_Source : constant String := "tools/phase579_language_validation_check.adb";

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   function Has (Path : String; Needle : String) return Boolean is
   begin
      return File_Contains (Path, Needle);
   end Has;

   procedure Require_Marker (Path : String; Marker : String; Category : String) is
   begin
      if not Has (Path, Marker) then
         Fail (Tool, Category & " missing required marker in " & Path & ": " & Marker);
      end if;
   end Require_Marker;

   procedure Forbid_Marker (Path : String; Marker : String; Category : String) is
   begin
      if Has (Path, Marker) then
         Fail (Tool, Category & " has forbidden stale marker in " & Path & ": " & Marker);
      end if;
   end Forbid_Marker;

   procedure Require_Syntax_Test (Name : String; Category : String) is
   begin
      Require_Marker (Syntax_Tests, Name, Category & " test coverage");
   end Require_Syntax_Test;

   procedure Require_Language_Model_API
     (Marker : String; Category : String) is
   begin
      Require_Marker
        (Language_Model_Spec, Marker, Category & " language-model API");
   end Require_Language_Model_API;

   procedure Require_Language_Model_Body
     (Marker : String; Category : String) is
   begin
      Require_Marker
        (Language_Model_Body, Marker, Category & " language-model body");
   end Require_Language_Model_Body;

   procedure Require_Parser_Projection
     (Marker : String; Category : String) is
   begin
      Require_Marker (Parser_Body, Marker, Category & " parser projection");
   end Require_Parser_Projection;

   procedure Require_Resolver_Body
     (Marker : String; Category : String) is
   begin
      Require_Marker (Resolver_Body, Marker, Category & " resolver path");
   end Require_Resolver_Body;

   procedure Require_Token_Cursor_Production
     (Marker : String; Category : String) is
   begin
      Require_Marker
        (Token_Cursor_Spec, Marker, Category & " token-cursor production");
   end Require_Token_Cursor_Production;

   procedure Require_Outline_Test (Name : String; Category : String) is
   begin
      Require_Marker (Outline_Tests, Name, Category & " test coverage");
   end Require_Outline_Test;

   procedure Check_Recent_Grammar_Pass_Guards is
   begin
      --  Phase 579 pass724-pass778 guard matrix.
      --  Keep recent grammar-depth regressions grouped by pass so a future
      --  failure points at the concrete parser/model family instead of an
      --  undifferentiated marker list.

      --  Pass724: object-declaration internals.
      Require_Token_Cursor_Production
        ("Production_Object_Defining_Name",
         "pass724 grouped object defining-name metadata");
      Require_Token_Cursor_Production
        ("Production_Object_Access_Definition",
         "pass724 anonymous access object definition metadata");
      Require_Token_Cursor_Production
        ("Production_Object_Declaration_Recovery_Boundary",
         "pass724 object declaration recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Object_Declaration_Depth_Grammar_Completeness",
         "pass724 object declaration grammar depth");

      --  Pass725: number-declaration internals.
      Require_Token_Cursor_Production
        ("Production_Number_Defining_Name",
         "pass725 named-number defining-name metadata");
      Require_Token_Cursor_Production
        ("Production_Number_Constant_Keyword",
         "pass725 named-number constant keyword metadata");
      Require_Token_Cursor_Production
        ("Production_Number_Declaration_Recovery_Boundary",
         "pass725 named-number recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Number_Declaration_Depth_Grammar_Completeness",
         "pass725 number declaration grammar depth");

      --  Pass816: named-number declaration completion metadata.
      Require_Token_Cursor_Production
        ("Production_Number_Declaration_Terminator",
         "pass816 named-number declaration terminator metadata");
      Require_Token_Cursor_Production
        ("Production_Number_Declaration_Missing_Terminator_Recovery_Boundary",
         "pass816 named-number missing-terminator recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Number_Declaration_Terminator_Pass816",
         "pass816 number declaration terminator recovery depth");

      --  Pass818: enumeration representation delimiter metadata.
      Require_Token_Cursor_Production
        ("Production_Enumeration_Representation_List_Open_Delimiter",
         "pass818 enumeration representation open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Representation_List_Close_Delimiter",
         "pass818 enumeration representation close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Representation_Association_Separator",
         "pass818 enumeration representation separator metadata");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Representation_Missing_Close_Recovery_Boundary",
         "pass818 enumeration representation missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Enumeration_Representation_Delimiters_Pass818",
         "pass818 enumeration representation delimiter recovery depth");

      --  Pass819: record representation delimiter metadata.
      Require_Token_Cursor_Production
        ("Production_Record_Representation_List_Open_Delimiter",
         "pass819 record representation open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Record_Representation_List_Close_Delimiter",
         "pass819 record representation close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Record_Representation_Component_Separator",
         "pass819 record representation component separator metadata");
      Require_Token_Cursor_Production
        ("Production_Record_Representation_Missing_Close_Recovery_Boundary",
         "pass819 record representation missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Record_Representation_Delimiters_Pass819",
         "pass819 record representation delimiter recovery depth");

      --  Pass820: pragma argument-list delimiter metadata.
      Require_Token_Cursor_Production
        ("Production_Pragma_Argument_List_Open_Delimiter",
         "pass820 pragma argument-list open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Pragma_Argument_List_Close_Delimiter",
         "pass820 pragma argument-list close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Pragma_Argument_Association_Separator",
         "pass820 pragma argument separator metadata");
      Require_Token_Cursor_Production
        ("Production_Pragma_Argument_List_Missing_Close_Recovery_Boundary",
         "pass820 pragma argument-list missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Pragma_Argument_Delimiters_Pass820",
         "pass820 pragma argument-list delimiter recovery depth");

      --  Pass821: call and entry-call actual-list delimiter metadata.
      Require_Token_Cursor_Production
        ("Production_Call_Actual_List_Open_Delimiter",
         "pass821 call actual-list open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Call_Actual_List_Close_Delimiter",
         "pass821 call actual-list close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Call_Actual_Association_Separator",
         "pass821 call actual separator metadata");
      Require_Token_Cursor_Production
        ("Production_Call_Actual_List_Missing_Close_Recovery_Boundary",
         "pass821 call actual-list missing-close recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Entry_Call_Actual_List_Open_Delimiter",
         "pass821 entry-call actual-list open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Entry_Call_Actual_List_Close_Delimiter",
         "pass821 entry-call actual-list close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Entry_Call_Actual_Association_Separator",
         "pass821 entry-call actual separator metadata");
      Require_Token_Cursor_Production
        ("Production_Entry_Call_Actual_List_Missing_Close_Recovery_Boundary",
         "pass821 entry-call actual-list missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Call_Actual_Delimiters_Pass821",
         "pass821 call and entry-call actual-list delimiter recovery depth");

      --  Pass822: generic instantiation actual-part delimiter metadata.
      Require_Token_Cursor_Production
        ("Production_Generic_Actual_Part_Open_Delimiter",
         "pass822 generic actual-part open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Generic_Actual_Part_Close_Delimiter",
         "pass822 generic actual-part close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Generic_Actual_Association_Separator",
         "pass822 generic actual separator metadata");
      Require_Token_Cursor_Production
        ("Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary",
         "pass822 generic actual-part missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters_Pass822",
         "pass822 generic instantiation actual-part delimiter recovery depth");

      --  Pass823: protected operation body end-name and terminator metadata.
      Require_Token_Cursor_Production
        ("Production_Protected_Body_Operation_End_Name",
         "pass823 protected operation body end-name metadata");
      Require_Token_Cursor_Production
        ("Production_Protected_Body_Operation_End_Terminator",
         "pass823 protected operation body end terminator metadata");
      Require_Token_Cursor_Production
        ("Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary",
         "pass823 protected operation body missing end-terminator recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail_Pass823",
         "pass823 protected operation body end-name and terminator recovery depth");

      --  Pass824: exception handler missing-choice recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Exception_Choice_Missing_Choice_Recovery_Boundary",
         "pass824 exception handler missing-choice recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice_Pass824",
         "pass824 exception handler choice-list recovery depth");

      --  Pass825: package visible/private declarative item recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Package_Visible_Declarative_Item_Recovery_Boundary",
         "pass825 package visible declarative item recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Package_Private_Declarative_Item_Recovery_Boundary",
         "pass825 package private declarative item recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Pass825",
         "pass825 package visible/private declarative item recovery depth");

      --  Pass826: parameter profile delimiter/separator recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Parameter_Profile_Open_Delimiter",
         "pass826 parameter profile open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Parameter_Profile_Close_Delimiter",
         "pass826 parameter profile close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Parameter_Profile_Separator",
         "pass826 parameter profile separator metadata");
      Require_Token_Cursor_Production
        ("Production_Parameter_Profile_Missing_Close_Recovery_Boundary",
         "pass826 parameter profile missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters_Pass826",
         "pass826 parameter profile delimiter and recovery depth");

      --  Pass827: discriminant part delimiter/separator recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Discriminant_Part_Open_Delimiter",
         "pass827 discriminant part open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Discriminant_Part_Close_Delimiter",
         "pass827 discriminant part close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Discriminant_Specification_Separator",
         "pass827 discriminant specification separator metadata");
      Require_Token_Cursor_Production
        ("Production_Discriminant_Part_Missing_Close_Recovery_Boundary",
         "pass827 discriminant part missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters_Pass827",
         "pass827 discriminant part delimiter and recovery depth");

      --  Pass828: index/discriminant constraint delimiter/separator recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Index_Constraint_Open_Delimiter",
         "pass828 index constraint open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Index_Constraint_Close_Delimiter",
         "pass828 index constraint close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Index_Constraint_Item_Separator",
         "pass828 index constraint item separator metadata");
      Require_Token_Cursor_Production
        ("Production_Index_Constraint_Missing_Close_Recovery_Boundary",
         "pass828 index constraint missing-close recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Discriminant_Constraint_Open_Delimiter",
         "pass828 discriminant constraint open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Discriminant_Constraint_Close_Delimiter",
         "pass828 discriminant constraint close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Discriminant_Association_Separator",
         "pass828 discriminant association separator metadata");
      Require_Token_Cursor_Production
        ("Production_Discriminant_Constraint_Missing_Close_Recovery_Boundary",
         "pass828 discriminant constraint missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Constraint_Delimiters_Pass828",
         "pass828 index/discriminant constraint delimiter and recovery depth");

      --  Pass829: aggregate delimiter/separator recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Aggregate_Open_Delimiter",
         "pass829 aggregate open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Aggregate_Close_Delimiter",
         "pass829 aggregate close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Aggregate_Component_Separator",
         "pass829 aggregate component separator metadata");
      Require_Token_Cursor_Production
        ("Production_Aggregate_Missing_Close_Recovery_Boundary",
         "pass829 aggregate missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Aggregate_Delimiters_Pass829",
         "pass829 aggregate delimiter and recovery depth");

      --  Pass830: qualified-expression operand delimiter recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Qualified_Expression_Operand_Open_Delimiter",
         "pass830 qualified-expression operand open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Qualified_Expression_Operand_Close_Delimiter",
         "pass830 qualified-expression operand close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Qualified_Expression_Operand_Missing_Close_Recovery_Boundary",
         "pass830 qualified-expression operand missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters_Pass830",
         "pass830 qualified-expression operand delimiter and recovery depth");

      --  Pass831: parenthesized-expression delimiter recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Parenthesized_Expression_Open_Delimiter",
         "pass831 parenthesized-expression open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Parenthesized_Expression_Close_Delimiter",
         "pass831 parenthesized-expression close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Parenthesized_Expression_Missing_Close_Recovery_Boundary",
         "pass831 parenthesized-expression missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters_Pass831",
         "pass831 parenthesized-expression delimiter and recovery depth");

      --  Pass832: discrete-choice separator and missing-choice recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Discrete_Choice_Separator",
         "pass832 discrete-choice separator metadata");
      Require_Token_Cursor_Production
        ("Production_Discrete_Choice_Missing_Choice_Recovery_Boundary",
         "pass832 discrete-choice missing-choice recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators_Pass832",
         "pass832 discrete-choice separator and recovery depth");

      --  Pass833: enumeration-type delimiter separator recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Enumeration_Type_Open_Delimiter",
         "pass833 enumeration type open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Type_Close_Delimiter",
         "pass833 enumeration type close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Literal_Separator",
         "pass833 enumeration literal separator metadata");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Type_Missing_Close_Recovery_Boundary",
         "pass833 enumeration type missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters_Pass833",
         "pass833 enumeration type delimiter and recovery depth");

      --  Pass834: digits/delta constraint expression recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Digits_Constraint_Expression",
         "pass834 digits constraint expression metadata");
      Require_Token_Cursor_Production
        ("Production_Digits_Constraint_Missing_Expression_Recovery_Boundary",
         "pass834 digits constraint missing-expression recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Delta_Constraint_Expression",
         "pass834 delta constraint expression metadata");
      Require_Token_Cursor_Production
        ("Production_Delta_Constraint_Missing_Expression_Recovery_Boundary",
         "pass834 delta constraint missing-expression recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions_Pass834",
         "pass834 digits/delta constraint expression and recovery depth");

      --  Pass835: range constraint bound/separator recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Range_Constraint_Range_Separator",
         "pass835 range constraint separator metadata");
      Require_Token_Cursor_Production
        ("Production_Range_Constraint_Missing_Lower_Bound_Recovery_Boundary",
         "pass835 range constraint missing-lower-bound recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Range_Constraint_Missing_Upper_Bound_Recovery_Boundary",
         "pass835 range constraint missing-upper-bound recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Range_Constraint_Bounds_Pass835",
         "pass835 range constraint bound separator and recovery depth");

      --  Pass836: attribute argument delimiter/separator recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Attribute_Argument_List_Open_Delimiter",
         "pass836 attribute argument open delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Attribute_Argument_List_Close_Delimiter",
         "pass836 attribute argument close delimiter metadata");
      Require_Token_Cursor_Production
        ("Production_Attribute_Argument_Association_Separator",
         "pass836 attribute argument association separator metadata");
      Require_Token_Cursor_Production
        ("Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary",
         "pass836 attribute argument missing-close recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters_Pass836",
         "pass836 attribute argument delimiter separator and recovery depth");

      --  Pass837: membership choice-list separator/recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Membership_Choice_Separator",
         "pass837 membership choice separator metadata");
      Require_Token_Cursor_Production
        ("Production_Membership_Choice_Missing_Choice_Recovery_Boundary",
         "pass837 membership choice missing-choice recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators_Pass837",
         "pass837 membership choice-list separator and recovery depth");

      --  Pass838: case-expression alternative separator/recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Case_Expression_Alternative_Separator",
         "pass838 case-expression alternative separator metadata");
      Require_Token_Cursor_Production
        ("Production_Case_Expression_Missing_Alternative_Recovery_Boundary",
         "pass838 case-expression missing-alternative recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators_Pass838",
         "pass838 case-expression alternative separator and recovery depth");

      --  Pass726: formal-package actual projection into model symbols.
      Require_Parser_Projection
        ("Node_Formal_Package_Declaration",
         "pass726 formal package syntax-tree projection");
      Require_Syntax_Test
        ("Test_Language_Model_Formal_Package_Actuals_Project_Into_Model",
         "pass726 formal package actual projection");

      --  Pass727: individual use-clause projection.
      Require_Language_Model_API
        ("Use_Clause_Count", "pass727 individual use-clause metadata");
      Require_Language_Model_API
        ("Use_Clause_At", "pass727 individual use-clause indexed access");
      Require_Resolver_Body
        ("Use_Clause_Count", "pass727 resolver consumes use-clause metadata");
      Require_Parser_Projection
        ("Segment_First", "pass727 comma-separated use-name ranges");
      Require_Syntax_Test
        ("Test_Language_Model_Use_Clauses_Project_Individual_Metadata",
         "pass727 use-clause projection");

      --  Pass728: formal-package actuals in resolver views.
      Require_Resolver_Body
        ("Symbol_Generic_Formal_Package",
         "pass728 formal package selected-name resolver view");
      Require_Resolver_Body
        ("Generic_Instance_For_Candidate",
         "pass728 generic instance/formal package candidate bridge");
      Require_Syntax_Test
        ("Test_Language_Model_Formal_Package_Actuals_Feed_Resolver_View",
         "pass728 formal package resolver view");

      --  Pass729: pragma placement and argument metadata.
      Require_Language_Model_API
        ("Pragma_Placement_Kind", "pass729 pragma placement kind");
      Require_Language_Model_API
        ("Pragma_Metadata_Count", "pass729 pragma metadata count");
      Require_Language_Model_API
        ("Pragma_Metadata_At", "pass729 pragma metadata access");
      Require_Parser_Projection
        ("Pragma_Placement_For_Node", "pass729 pragma placement projection");
      Require_Parser_Projection
        ("Pragma_Metadata_Named_Argument_Count",
         "pass729 pragma named argument projection");
      Require_Syntax_Test
        ("Test_Language_Model_Pragma_Placement_And_Target_Metadata",
         "pass729 pragma placement target and argument metadata");

      --  Pass730: less-common aspect placement productions.
      Require_Token_Cursor_Production
        ("Production_Generic_Formal_Aspect_Specification",
         "pass730 generic formal aspect placement");
      Require_Token_Cursor_Production
        ("Production_Concurrent_Type_Aspect_Specification",
         "pass730 concurrent type aspect placement");
      Require_Token_Cursor_Production
        ("Production_Entry_Aspect_Specification",
         "pass730 entry aspect placement");
      Require_Token_Cursor_Production
        ("Production_Protected_Operation_Aspect_Attachment",
         "pass730 protected operation aspect placement");
      Require_Token_Cursor_Production
        ("Production_Body_Stub_Aspect_Specification",
         "pass730 body-stub aspect placement");
      Require_Token_Cursor_Production
        ("Production_Private_Completion_Aspect_Specification",
         "pass730 private completion aspect placement");
      Require_Token_Cursor_Production
        ("Production_Body_Aspect_Specification",
         "pass730 body aspect placement");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Aspect_Placement_Grammar_Completeness",
         "pass730 aspect placement grammar depth");

      --  Pass731: representation/operational source-form projection.
      Require_Language_Model_API
        ("Representation_Source_Form", "pass731 representation source form");
      Require_Language_Model_API
        ("Representation_Source_Record_Component_Clause",
         "pass731 component clause source form");
      Require_Parser_Projection
        ("Clause_Source_Form", "pass731 representation clause source form");
      Require_Syntax_Test
        ("Test_Language_Model_Representation_Operational_Projection_Metadata",
         "pass731 representation operational projection");

      --  Pass732: package declarative-item hostile recovery.
      Require_Token_Cursor_Production
        ("Production_Package_Declarative_Recovery_Boundary",
         "pass732 package declarative recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Package_Unexpected_Begin_Boundary",
         "pass732 package spec unexpected begin boundary");
      Require_Token_Cursor_Production
        ("Production_Package_Body_Unexpected_Private_Boundary",
         "pass732 package body unexpected private boundary");
      Require_Marker
        (Token_Cursor_Body, "Starts_Strong_Package_Declarative_Item",
         "pass732 package-aware recovery synchronizer");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Package_Declarative_Item_Hostile_Recovery",
         "pass732 package declarative hostile recovery");

      --  Pass937: package declarative section recovery depth.
      Require_Token_Cursor_Production
        ("Production_Package_Duplicate_Private_Boundary",
         "pass937 duplicate package private recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Package_Private_Begin_Recovery_Boundary",
         "pass937 package private begin recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Package_Body_Private_Declarative_Recovery_Boundary",
         "pass937 package-body private declarative recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth_Pass937",
         "pass937 package declarative section recovery depth");

      --  Pass939: expression recovery refinement depth.
      Require_Token_Cursor_Production
        ("Production_If_Expression_Condition_Reserved_Boundary",
         "pass939 if-expression condition reserved boundary");
      Require_Token_Cursor_Production
        ("Production_Case_Expression_Missing_Selector_Recovery_Boundary",
         "pass939 case-expression missing selector recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Case_Expression_Missing_Is_Recovery_Boundary",
         "pass939 case-expression missing-is recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Parallel_Reduction_Argument_Recovery_Boundary",
         "pass939 parallel reduction argument recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth_Pass939",
         "pass939 expression recovery refinement depth");

      --  Pass733: anonymous access-to-subprogram edge profiles.
      Require_Token_Cursor_Production
        ("Production_Access_Subprogram_Null_Exclusion",
         "pass733 access-subprogram null exclusion");
      Require_Token_Cursor_Production
        ("Production_Access_Subprogram_Parameter_Default",
         "pass733 access-subprogram parameter default");
      Require_Token_Cursor_Production
        ("Production_Access_Subprogram_Result_Null_Exclusion",
         "pass733 access-function result null exclusion");
      Require_Token_Cursor_Production
        ("Production_Access_Subprogram_Result_Constraint",
         "pass733 access-function result constraint");
      Require_Token_Cursor_Production
        ("Production_Access_Subprogram_Profile_Recovery_Boundary",
         "pass733 access-subprogram profile recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Edge_Recovery",
         "pass733 anonymous access-subprogram edge recovery");

      --  Pass734: expression/name edge-case recovery.
      Require_Token_Cursor_Production
        ("Production_Allocator_Nested_Qualified_Expression",
         "pass734 allocator qualified-expression edge");
      Require_Token_Cursor_Production
        ("Production_Conversion_Or_Qualified_Expression",
         "pass734 conversion/qualified-expression ambiguity");
      Require_Token_Cursor_Production
        ("Production_Chained_Attribute_Reference",
         "pass734 chained attribute reference");
      Require_Token_Cursor_Production
        ("Production_Call_Or_Indexed_Component",
         "pass734 call/index/slice ambiguity");
      Require_Token_Cursor_Production
        ("Production_Reduction_Argument_Recovery_Boundary",
         "pass734 reduction argument recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Expression_Name_Edge_Recovery",
         "pass734 expression/name edge recovery");

      --  Pass737: case-statement alternative depth metadata.
      Require_Token_Cursor_Production
        ("Production_Case_Statement_Is_Keyword",
         "pass737 case statement is keyword boundary");
      Require_Token_Cursor_Production
        ("Production_Case_Statement_Missing_Is_Recovery_Boundary",
         "pass866 case statement missing-is recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Case_Choice",
         "pass737 individual case choice metadata");
      Require_Token_Cursor_Production
        ("Production_Case_Range_Choice",
         "pass737 case range choice metadata");
      Require_Token_Cursor_Production
        ("Production_Case_Alternative_Null_Statement",
         "pass737 case alternative null statement marker");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Case_Statement_Alternative_Depth",
         "pass737 case statement alternative depth");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Case_Statement_Is_Recovery_Pass866",
         "pass866 case statement missing-is recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Case_Choice_Missing_Choice_Recovery_Boundary",
         "pass867 case choice missing-choice recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery_Pass867",
         "pass867 case choice missing-choice recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Case_Alternative_Missing_Statement_Recovery_Boundary",
         "pass868 case alternative missing-statement recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Case_Alternative_Statement_Recovery_Pass868",
         "pass868 case alternative missing-statement recovery coverage");
      Require_Token_Cursor_Production
        ("Production_If_Then_Missing_Statement_Recovery_Boundary",
         "pass869 if then branch missing-statement recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Loop_Missing_Statement_Recovery_Boundary",
         "pass870 loop body missing-statement recovery production");
      Require_Token_Cursor_Production
        ("Production_Block_Missing_Statement_Recovery_Boundary",
         "pass871 block statement-sequence missing-statement recovery production");
      Require_Token_Cursor_Production
        ("Production_Case_Alternative_End_Case_Statement_Recovery_Boundary",
         "pass872 terminal case alternative missing-statement recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Case_Alternative_End_Case_Statement_Recovery_Pass872",
         "pass872 terminal case alternative missing-statement recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Exception_Handler_Missing_Statement_Recovery_Boundary",
         "pass874 exception handler missing-statement recovery production");
      Require_Token_Cursor_Production
        ("Production_Exception_Handler_End_Statement_Recovery_Boundary",
         "pass874 terminal exception handler missing-statement recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Exception_Handler_Statement_Recovery_Pass874",
         "pass874 exception handler missing-statement recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Use_Clause_Missing_Name_Recovery_Boundary",
         "pass875 use-clause missing-name recovery production");
      Require_Token_Cursor_Production
        ("Production_Use_Clause_Trailing_Separator_Recovery_Boundary",
         "pass875 use-clause trailing-separator recovery production");
      Require_Token_Cursor_Production
        ("Production_Use_Clause_Missing_Terminator_Recovery_Boundary",
         "pass875 use-clause missing-terminator recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery_Pass875",
         "pass875 use-clause specific recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Representation_Empty_List_Recovery_Boundary",
         "pass876 empty enumeration representation list recovery production");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Representation_Trailing_Separator_Recovery_Boundary",
         "pass876 enumeration representation trailing-separator recovery production");
      Require_Token_Cursor_Production
        ("Production_Enumeration_Representation_Missing_Value_Recovery_Boundary",
         "pass876 enumeration representation missing-value recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Enumeration_Representation_Recovery_Pass876",
         "pass876 enumeration representation specific recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Subprogram_Declaration_Aspect_Specification",
         "pass877 subprogram declaration aspect placement production");
      Require_Token_Cursor_Production
        ("Production_Subprogram_Body_Aspect_Specification",
         "pass877 subprogram body aspect placement production");
      Require_Token_Cursor_Production
        ("Production_Subprogram_Contract_Aspect_Placement",
         "pass877 subprogram contract aspect placement production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Pass877",
         "pass877 subprogram contract aspect placement coverage");
      Require_Token_Cursor_Production
        ("Production_Package_Nested_Declarative_Item_Recovery_Boundary",
         "pass878 package nested declarative item recovery production");
      Require_Token_Cursor_Production
        ("Production_Package_Declarative_Private_Boundary",
         "pass878 package private boundary production");
      Require_Token_Cursor_Production
        ("Production_Package_Declarative_Begin_Boundary",
         "pass878 package begin boundary production");
      Require_Token_Cursor_Production
        ("Production_Package_Declarative_End_Boundary",
         "pass878 package end boundary production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Pass878",
         "pass878 package declarative item recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Access_Protected_Missing_Subprogram_Recovery_Boundary",
         "pass879 protected anonymous access missing subprogram recovery production");
      Require_Token_Cursor_Production
        ("Production_Access_Function_Missing_Return_Recovery_Boundary",
         "pass879 access-to-function missing return recovery production");
      Require_Token_Cursor_Production
        ("Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary",
         "pass879 access-to-function missing result subtype recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refined_Recovery_Pass879",
         "pass879 anonymous access-to-subprogram refined recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Access_Object_Missing_Subtype_Recovery_Boundary",
         "pass929 access-to-object missing designated subtype recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Access_Object_Missing_Subtype_Recovery_Pass929",
         "pass929 access-to-object missing subtype reserved-boundary recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Access_Mode_Missing_Subtype_Recovery_Boundary",
         "pass930 access all/constant missing subtype recovery production");
      Require_Token_Cursor_Production
        ("Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary",
         "pass930 access mode/subprogram conflict recovery production");
      Require_Token_Cursor_Production
        ("Production_Access_Protected_Missing_Subprogram_Boundary_Token",
         "pass930 access protected missing subprogram boundary token production");
      Require_Token_Cursor_Production
        ("Production_Access_Result_Missing_Subtype_Recovery_Boundary",
         "pass930 access function result missing subtype recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth_Pass930",
         "pass930 access definition recovery depth coverage");
      Require_Token_Cursor_Production
        ("Production_Formal_Subprogram_Default_Abstract_Name",
         "pass931 formal subprogram abstract default designator production");
      Require_Token_Cursor_Production
        ("Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary",
         "pass931 formal subprogram missing default recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery_Pass931",
         "pass931 generic formal subprogram default recovery coverage");
      Require_Token_Cursor_Production
        ("Production_If_Expression_Missing_Condition_Recovery_Boundary",
         "pass880 conditional expression missing condition recovery production");
      Require_Token_Cursor_Production
        ("Production_If_Expression_Missing_Then_Branch_Recovery_Boundary",
         "pass880 conditional expression missing then branch recovery production");
      Require_Token_Cursor_Production
        ("Production_If_Expression_Missing_Else_Branch_Recovery_Boundary",
         "pass880 conditional expression missing else branch recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Conditional_Expression_Recovery_Pass880",
         "pass880 conditional expression operand recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Qualified_Expression_Selected_Literal_Subtype_Mark",
         "pass881 qualified-expression selected literal subtype-mark production");
      Require_Token_Cursor_Production
        ("Production_Qualified_Expression_Selected_Operator_Subtype_Mark",
         "pass881 qualified-expression selected operator subtype-mark production");
      Require_Token_Cursor_Production
        ("Production_Qualified_Expression_Selected_Character_Subtype_Mark",
         "pass881 qualified-expression selected character subtype-mark production");
      Require_Token_Cursor_Production
        ("Production_Allocator_Selected_Operator_Subtype_Mark",
         "pass881 allocator selected operator subtype-mark production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Selected_Literal_Name_Refinement_Pass881",
         "pass881 selected literal name refinement coverage");
      Require_Token_Cursor_Production
        ("Production_Select_Alternative_Missing_Statement_Recovery_Boundary",
         "pass882 select alternative missing statement recovery production");
      Require_Token_Cursor_Production
        ("Production_Select_Else_Missing_Statement_Recovery_Boundary",
         "pass882 select else missing statement recovery production");
      Require_Token_Cursor_Production
        ("Production_Select_Abortable_Missing_Statement_Recovery_Boundary",
         "pass882 select abortable missing statement recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Select_Alternative_Statement_Recovery_Pass882",
         "pass882 select alternative statement recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Formal_Package_Actual_Empty_Recovery_Boundary",
         "pass873 empty formal package actual recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery_Pass873",
         "pass873 empty formal package actual recovery coverage");
      Require_Token_Cursor_Production
        ("Production_Elsif_Missing_Statement_Recovery_Boundary",
         "pass869 elsif branch missing-statement recovery boundary");
      Require_Token_Cursor_Production
        ("Production_Else_Missing_Statement_Recovery_Boundary",
         "pass869 else branch missing-statement recovery boundary");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_If_Branch_Statement_Recovery_Pass869",
         "pass869 if branch missing-statement recovery coverage");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Loop_Body_Statement_Recovery_Pass870",
         "pass870 loop body missing-statement recovery coverage");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Block_Body_Statement_Recovery_Pass871",
         "pass871 block statement-sequence missing-statement recovery coverage");

      --  Pass738: select-statement alternative depth metadata.
      Require_Token_Cursor_Production
        ("Production_Select_First_Alternative",
         "pass738 select first alternative marker");
      Require_Token_Cursor_Production
        ("Production_Select_Accept_Alternative",
         "pass738 select accept alternative marker");
      Require_Token_Cursor_Production
        ("Production_Select_Delay_Until_Alternative",
         "pass738 select delay until alternative marker");
      Require_Token_Cursor_Production
        ("Production_Select_Delay_Relative_Alternative",
         "pass738 select relative delay alternative marker");
      Require_Token_Cursor_Production
        ("Production_Select_Terminate_Alternative",
         "pass738 select terminate alternative marker");
      Require_Token_Cursor_Production
        ("Production_Select_Guard_Arrow",
         "pass738 select guard arrow marker");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Select_Statement_Alternative_Depth",
         "pass738 select statement alternative depth");

      --  Pass739: exception-handler choice depth metadata.
      Require_Token_Cursor_Production
        ("Production_Exception_Named_Choice",
         "pass739 named exception choice marker");
      Require_Token_Cursor_Production
        ("Production_Exception_Selected_Choice",
         "pass739 selected exception choice marker");
      Require_Token_Cursor_Production
        ("Production_Exception_Handler_Null_Statement",
         "pass739 exception handler null statement marker");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Exception_Handler_Choice_Depth",
         "pass739 exception handler choice depth");

      --  Pass740: loop iteration-scheme depth metadata.
      Require_Token_Cursor_Production
        ("Production_While_Loop_Keyword",
         "pass740 while loop keyword marker");
      Require_Token_Cursor_Production
        ("Production_For_Loop_Reverse_Iteration",
         "pass740 discrete for-loop reverse iteration marker");
      Require_Token_Cursor_Production
        ("Production_For_Loop_Range_Iteration",
         "pass740 discrete for-loop range iteration marker");
      Require_Token_Cursor_Production
        ("Production_Iterator_Loop_Reverse_Iteration",
         "pass740 iterator for-loop reverse iteration marker");
      Require_Token_Cursor_Production
        ("Production_Loop_Iterator_Filter_Condition",
         "pass740 loop iterator filter condition marker");
      Require_Token_Cursor_Production
        ("Production_Loop_Begin_Keyword",
         "pass740 loop begin keyword marker");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Loop_Iteration_Scheme_Metadata",
         "pass740 loop iteration scheme metadata");

      --  Pass741: entry-family/index and selected entry-call depth metadata.
      Require_Token_Cursor_Production
        ("Production_Entry_Family_Range_Definition",
         "pass741 entry family range definition marker");
      Require_Token_Cursor_Production
        ("Production_Entry_Body_Index_Identifier",
         "pass741 entry body index identifier marker");
      Require_Token_Cursor_Production
        ("Production_Entry_Body_Index_Subtype",
         "pass741 entry body index subtype marker");
      Require_Token_Cursor_Production
        ("Production_Entry_Barrier_When_Keyword",
         "pass741 entry barrier when keyword marker");
      Require_Token_Cursor_Production
        ("Production_Accept_Entry_Index_Expression",
         "pass741 accept entry index expression marker");
      Require_Token_Cursor_Production
        ("Production_Entry_Call_Selected_Target",
         "pass741 selected entry-call target marker");
      Require_Token_Cursor_Production
        ("Production_Entry_Call_Selected_Entry_Name",
         "pass741 selected entry-call name marker");
      Require_Token_Cursor_Production
        ("Production_Entry_Call_Family_Index",
         "pass741 entry-call family index marker");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Entry_Family_Index_Depth",
         "pass741 entry family index and selected entry-call metadata");

      --  Pass742: variant-record component alternative depth metadata.
      Require_Token_Cursor_Production
        ("Production_Variant_Discrete_Choice",
         "pass742 variant discrete choice marker");
      Require_Token_Cursor_Production
        ("Production_Variant_Range_Choice",
         "pass742 variant range choice marker");
      Require_Token_Cursor_Production
        ("Production_Variant_Component_Declaration",
         "pass742 variant component declaration marker");
      Require_Token_Cursor_Production
        ("Production_Variant_Null_Component_Part",
         "pass742 variant null component part marker");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Variant_Record_Component_Depth",
         "pass742 variant record component alternative depth");

      --  Pass743: aggregate association depth metadata.
      Require_Token_Cursor_Production
        ("Production_Aggregate_Index_Choice",
         "pass743 aggregate index/component choice marker");
      Require_Token_Cursor_Production
        ("Production_Aggregate_Range_Choice",
         "pass743 aggregate range choice marker");
      Require_Token_Cursor_Production
        ("Production_Aggregate_Box_Component",
         "pass743 aggregate box component marker");
      Require_Token_Cursor_Production
        ("Production_Extension_Aggregate_Component_Association",
         "pass743 extension aggregate component association marker");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness",
         "pass743 aggregate association depth metadata");

      --  Pass744: subprogram/profile parameter mode projection metadata.
      Require_Language_Model_API
        ("Profile_Parameter_Info",
         "pass744 profile parameter metadata record");
      Require_Language_Model_API
        ("Profile_Parameter_Mode",
         "pass744 profile parameter mode classification");
      Require_Language_Model_API
        ("Profile_Parameter_Count",
         "pass744 profile parameter metadata count");
      Require_Language_Model_API
        ("Profile_Parameter_At",
         "pass744 profile parameter indexed metadata access");
      Require_Parser_Projection
        ("Add_Profile_Parameter_Metadata",
         "pass744 profile parameter parser projection");
      Require_Syntax_Test
        ("Test_Language_Model_Subprogram_Profile_Parameter_Mode_Metadata",
         "pass744 subprogram profile parameter mode projection");

      --  Pass745: generic formal type detail projection metadata.
      Require_Language_Model_API
        ("Generic_Formal_Type_Info",
         "pass745 generic formal type metadata record");
      Require_Language_Model_API
        ("Generic_Formal_Type_Family",
         "pass745 generic formal type family classification");
      Require_Language_Model_API
        ("Generic_Formal_Type_Metadata_Count",
         "pass745 generic formal type metadata count");
      Require_Language_Model_API
        ("Generic_Formal_Type_Metadata_At",
         "pass745 generic formal type indexed metadata access");
      Require_Parser_Projection
        ("Add_Generic_Formal_Type_Metadata",
         "pass745 generic formal type parser projection");
      Require_Syntax_Test
        ("Test_Language_Model_Generic_Formal_Type_Detail_Metadata",
         "pass745 generic formal type detail projection");

      --  Pass746: conservative syntax-recovery legality diagnostics.
      Require_Language_Model_API
        ("Legality_Malformed_Pragma_Syntax",
         "pass746 malformed pragma diagnostic kind");
      Require_Language_Model_API
        ("Legality_Malformed_Aspect_Association",
         "pass746 malformed aspect diagnostic kind");
      Require_Language_Model_API
        ("Legality_Missing_Metadata_Terminator",
         "pass746 missing metadata terminator diagnostic kind");
      Require_Language_Model_API
        ("Legality_Missing_Declaration_Terminator",
         "pass746 missing declaration terminator diagnostic kind");
      Require_Parser_Projection
        ("Check_Syntax_Recovery_Diagnostics",
         "pass746 syntax-recovery diagnostic projection");
      Require_Syntax_Test
        ("Test_Language_Model_Conservative_Syntax_Recovery_Diagnostics",
         "pass746 conservative syntax recovery diagnostics");

      --  Pass747: hostile-source recovery matrix across unrelated families.
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Hostile_Source_Recovery_Matrix",
         "pass747 hostile mixed-source recovery matrix");
      Require_Syntax_Test
        ("hostile generic formal-package actual recovery must remain bounded",
         "pass747 generic hostile recovery assertion");
      Require_Syntax_Test
        ("broken aggregate associations must retain an explicit recovery boundary",
         "pass747 aggregate hostile recovery assertion");
      Require_Syntax_Test
        ("broken select guards must retain an explicit recovery boundary",
         "pass747 select hostile recovery assertion");
      Require_Syntax_Test
        ("broken exception handlers must retain an explicit recovery boundary",
         "pass747 exception hostile recovery assertion");
      Require_Syntax_Test
        ("malformed variant alternatives must retain an explicit recovery boundary",
         "pass747 variant hostile recovery assertion");

      --  Pass748: extended return object qualifier and constraint depth.
      Require_Token_Cursor_Production
        ("Production_Return_Object_Aliased_Qualifier",
         "pass748 extended return aliased qualifier production");
      Require_Token_Cursor_Production
        ("Production_Return_Object_Constant_Qualifier",
         "pass748 extended return constant qualifier production");
      Require_Token_Cursor_Production
        ("Production_Return_Object_Access_Definition",
         "pass748 extended return access-definition production");
      Require_Token_Cursor_Production
        ("Production_Return_Object_Null_Exclusion",
         "pass748 extended return null-exclusion production");
      Require_Token_Cursor_Production
        ("Production_Return_Object_Constraint",
         "pass748 extended return constraint production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Extended_Return_Object_Qualifier_Depth",
         "pass748 extended return object qualifier regression");

      --  Pass749: abort statement target-shape depth and recovery.
      Require_Token_Cursor_Production
        ("Production_Abort_Selected_Target",
         "pass749 abort selected target production");
      Require_Token_Cursor_Production
        ("Production_Abort_Indexed_Target",
         "pass749 abort indexed target production");
      Require_Token_Cursor_Production
        ("Production_Abort_Dereferenced_Target",
         "pass749 abort dereferenced target production");
      Require_Token_Cursor_Production
        ("Production_Abort_Target_Separator",
         "pass749 abort target separator production");
      Require_Token_Cursor_Production
        ("Production_Abort_Recovery_Boundary",
         "pass749 abort recovery boundary production");
      Require_Syntax_Test
        ("Production_Abort_Selected_Target",
         "pass749 abort target-shape regression");

      --  Pass750: raise statement / raise expression target and message depth.
      Require_Token_Cursor_Production
        ("Production_Raise_Selected_Exception_Name",
         "pass750 selected raise-statement exception production");
      Require_Token_Cursor_Production
        ("Production_Raise_Expression_Selected_Exception_Name",
         "pass750 selected raise-expression exception production");
      Require_Token_Cursor_Production
        ("Production_Raise_With_Message_Keyword",
         "pass750 raise with-message keyword production");
      Require_Token_Cursor_Production
        ("Production_Raise_Message_Recovery_Boundary",
         "pass750 raise message recovery production");
      Require_Token_Cursor_Production
        ("Production_Raise_Expression_Recovery_Boundary",
         "pass750 raise-expression recovery production");
      Require_Syntax_Test
        ("raise expressions must classify selected exception names",
         "pass750 raise expression selected-name regression");
      Require_Syntax_Test
        ("malformed raise with-message clauses must expose bounded recovery markers",
         "pass750 raise with-message recovery regression");

      --  Pass751: standalone delay statement expression-shape and terminator depth.
      Require_Token_Cursor_Production
        ("Production_Delay_Until_Keyword",
         "pass751 standalone delay until keyword production");
      Require_Token_Cursor_Production
        ("Production_Delay_Selected_Time_Expression",
         "pass751 selected delay expression production");
      Require_Token_Cursor_Production
        ("Production_Delay_Qualified_Time_Expression",
         "pass751 qualified delay expression production");
      Require_Token_Cursor_Production
        ("Production_Delay_Statement_Terminator",
         "pass751 delay terminator production");
      Require_Syntax_Test
        ("standalone delay statements must retain selected time-expression prefixes",
         "pass751 selected delay expression regression");
      Require_Syntax_Test
        ("standalone delay statements must retain qualified duration expressions",
         "pass751 qualified delay expression regression");

      --  Pass752: requeue target depth.
      Require_Token_Cursor_Production
        ("Production_Requeue_Selected_Target",
         "pass752 selected requeue-target production");
      Require_Token_Cursor_Production
        ("Production_Requeue_Indexed_Target",
         "pass752 indexed requeue-target production");
      Require_Token_Cursor_Production
        ("Production_Requeue_Target_Recovery_Boundary",
         "pass752 requeue target recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Requeue_Grammar_Completeness",
         "pass752 requeue grammar regression");

      --  Pass753: label/goto delimiter, terminator, and recovery metadata.
      Require_Token_Cursor_Production
        ("Production_Label_Open_Delimiter",
         "pass753 label open delimiter production");
      Require_Token_Cursor_Production
        ("Production_Label_Close_Delimiter",
         "pass753 label close delimiter production");
      Require_Token_Cursor_Production
        ("Production_Label_Recovery_Boundary",
         "pass753 label recovery production");
      Require_Token_Cursor_Production
        ("Production_Goto_Terminator",
         "pass753 goto terminator production");
      Require_Token_Cursor_Production
        ("Production_Goto_Label_Recovery_Boundary",
         "pass753 goto label-name recovery production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Label_Goto_Metadata_Depth",
         "pass753 label/goto metadata regression");

      --  Pass754: block statement declarative-part and block-label depth.
      Require_Token_Cursor_Production
        ("Production_Block_Declare_Keyword",
         "pass754 block declare-keyword production");
      Require_Token_Cursor_Production
        ("Production_Block_Declarative_Begin_Boundary",
         "pass754 block declarative begin-boundary production");
      Require_Token_Cursor_Production
        ("Production_Block_Declarative_Item_Start",
         "pass754 block declarative-item start production");
      Require_Token_Cursor_Production
        ("Production_Block_Exception_Keyword",
         "pass754 block exception-keyword production");
      Require_Token_Cursor_Production
        ("Production_Block_Label_Name",
         "pass754 named block label production");
      Require_Syntax_Test
        ("block declarative-item starts must be retained explicitly",
         "pass754 block declarative-item metadata regression");

      --  Pass755: task/protected body internal operation and recovery depth.
      Require_Token_Cursor_Production
        ("Production_Task_Body_Declarative_Item_Start",
         "pass755 task body declarative-item start production");
      Require_Token_Cursor_Production
        ("Production_Task_Body_Begin_Keyword",
         "pass755 task body begin keyword production");
      Require_Token_Cursor_Production
        ("Production_Task_Body_End_Keyword",
         "pass755 task body end keyword production");
      Require_Token_Cursor_Production
        ("Production_Protected_Body_Operation_Begin_Keyword",
         "pass755 protected operation begin keyword production");
      Require_Token_Cursor_Production
        ("Production_Protected_Body_Operation_End_Keyword",
         "pass755 protected operation end keyword production");
      Require_Token_Cursor_Production
        ("Production_Protected_Body_Recovery_Boundary",
         "pass755 protected body recovery boundary production");
      Require_Syntax_Test
        ("misplaced protected-body private sections must retain a recovery boundary",
         "pass755 protected body recovery regression");

      --  Pass756: entry/procedure call ambiguity metadata.
      Require_Token_Cursor_Production
        ("Production_Call_Selected_Prefix",
         "pass756 selected call prefix production");
      Require_Token_Cursor_Production
        ("Production_Call_Selected_Operation_Name",
         "pass756 selected call operation-name production");
      Require_Token_Cursor_Production
        ("Production_Call_Dispatching_Prefix",
         "pass756 dispatching-style call prefix production");
      Require_Token_Cursor_Production
        ("Production_Call_Indexed_Prefix",
         "pass756 indexed call prefix production");
      Require_Token_Cursor_Production
        ("Production_Call_Entry_Family_Ambiguity",
         "pass756 entry/procedure call ambiguity production");
      Require_Syntax_Test
        ("entry-family versus procedure-call ambiguity must be exposed structurally",
         "pass756 entry/procedure call ambiguity regression");

      --  Pass757: separate subunit and body-stub relation metadata.
      Require_Token_Cursor_Production
        ("Production_Separate_Parent_Unit_Separator",
         "pass757 separate parent-unit separator production");
      Require_Token_Cursor_Production
        ("Production_Separate_Parent_Unit_Child",
         "pass757 separate parent-unit child production");
      Require_Token_Cursor_Production
        ("Production_Separate_Body_Kind_Keyword",
         "pass757 separate body kind keyword production");
      Require_Token_Cursor_Production
        ("Production_Separate_Body_Unit_Name",
         "pass757 separate body unit name production");
      Require_Token_Cursor_Production
        ("Production_Body_Stub_Subunit_Link_Hint",
         "pass757 body-stub subunit link hint production");
      Require_Syntax_Test
        ("body stubs must retain conservative subunit-link hint metadata",
         "pass757 separate subunit/body-stub regression");

      --  Pass758: context-clause detail projection.
      Require_Language_Model_API
        ("Context_Clause_Count",
         "pass758 context-clause count API");
      Require_Language_Model_API
        ("Has_Limited_Modifier",
         "pass758 context-clause modifier metadata");
      Require_Language_Model_Body
        ("Info.Is_Context_Clause",
         "pass758 context-clause projection body");
      Require_Parser_Projection
        ("Saw_Limited, Saw_Private",
         "pass758 context-clause modifier projection");
      Require_Syntax_Test
        ("context-clause projection must retain each root with/use name separately",
         "pass758 context-clause detail projection regression");


      --  Pass759: local duplicate representation-clause diagnostics.
      Require_Language_Model_Body
        ("Same_Local_Representation_Target",
         "pass759 local duplicate representation target helper");
      Require_Language_Model_Body
        ("duplicate representation diagnostics should be local and resolved",
         "pass759 local duplicate representation comment");
      Require_Syntax_Test
        ("duplicate representation diagnostics should be local to the resolved target symbol",
         "pass759 local duplicate representation regression");

      --  Pass760: refreshed coverage matrix after pass737-pass759.
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Ada parser coverage matrix — Phase 579 pass770",
         "pass761 refreshed coverage matrix title");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Case/select/exception alternatives",
         "pass760 alternatives matrix row");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Loop iteration schemes",
         "pass760 loop scheme matrix row");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Entry/tasking statements",
         "pass760 entry tasking matrix row");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Separate subunits and body stubs",
         "pass760 separate subunit matrix row");

      --  Pass761: semantic-colouring consumers for newer language-model metadata.
      Require_Marker
        ("src/core/editor-syntax_semantics.adb",
         "Pass761: newer parser/model metadata families are now consumed",
         "pass761 semantic-colouring consumer body");
      Require_Marker
        ("src/core/editor-syntax_semantics.adb",
         "Generic_Formal_Type_Metadata_Count",
         "pass761 generic formal metadata consumer");
      Require_Marker
        ("src/core/editor-syntax_semantics.adb",
         "Pragma_Metadata_Count",
         "pass761 pragma metadata consumer");
      Require_Syntax_Test
        ("semantic colouring consumes newer Ada language-model metadata families",
         "pass761 semantic-colouring consumer regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Semantic-colouring metadata consumers",
         "pass761 matrix semantic-colouring consumer row");

      --  Pass762: resolver-facing call ambiguity hints.
      Require_Marker
        ("src/core/editor-ada_language_model.ads",
         "Binding_Call_Selected_Prefix",
         "pass762 selected call prefix binding kind");
      Require_Marker
        ("src/core/editor-ada_language_model.ads",
         "Binding_Call_Entry_Family_Candidate",
         "pass762 entry-family candidate binding kind");
      Require_Marker
        ("src/core/editor-ada_declaration_parser.adb",
         "Pass 762: retain syntax/model hints for call-shaped ambiguity",
         "pass762 call ambiguity hint scanner");
      Require_Syntax_Test
        ("language model projects call ambiguity resolver hints",
         "pass762 call ambiguity resolver hint regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Call/entry-call resolver hints",
         "pass762 matrix call ambiguity resolver hint row");

      --  Pass763: subprogram/entry body-stub aspect placement depth.
      Require_Marker
        ("src/core/editor-ada_token_cursor.adb",
         "Subprogram body stubs have body-stub aspect placement",
         "pass763 subprogram body-stub aspect placement parser path");
      Require_Marker
        ("src/core/editor-ada_token_cursor.adb",
         "Entry body stubs share entry grammar before",
         "pass763 entry body-stub aspect placement parser path");
      Require_Syntax_Test
        ("token-cursor grammar retains subprogram and entry body-stub aspect placement",
         "pass763 body-stub aspect placement regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "subprogram/entry/package/task/protected body stubs",
         "pass763 matrix body-stub aspect placement row");

      --  Pass764: formal-package positional actual association depth.
      Require_Token_Cursor_Production
        ("Production_Formal_Package_Actual_Positional_Association",
         "pass764 formal package positional actual production");
      Require_Syntax_Test
        ("token-cursor grammar tags formal package positional actual associations distinctly",
         "pass764 formal package positional actual regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "positional associations, named associations",
         "pass764 matrix formal package positional actual row");

      --  Pass765: formal-package defaulted actual-part depth.
      Require_Token_Cursor_Production
        ("Production_Formal_Package_Defaulted_Actual_Part",
         "pass765 formal package defaulted actual-part production");
      Require_Syntax_Test
        ("token-cursor grammar tags defaulted formal package actual parts",
         "pass765 formal package defaulted actual-part regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "defaulted actual parts, boxes",
         "pass765 matrix formal package defaulted actual-part row");

      --  Pass766: representation/operational pragma item depth.
      Require_Token_Cursor_Production
        ("Production_Representation_Pragma",
         "pass766 representation pragma production");
      Require_Token_Cursor_Production
        ("Production_Operational_Pragma",
         "pass766 operational pragma production");
      Require_Syntax_Test
        ("token-cursor grammar classifies representation and operational pragmas structurally",
         "pass766 representation pragma item regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "operational pragmas",
         "pass766 matrix representation pragma item row");

      --  Pass767: pragma argument association depth.
      Require_Token_Cursor_Production
        ("Production_Pragma_Argument_Named_Association",
         "pass767 pragma named association production");
      Require_Token_Cursor_Production
        ("Production_Pragma_Argument_Positional_Association",
         "pass767 pragma positional association production");
      Require_Token_Cursor_Production
        ("Production_Pragma_Argument_Box",
         "pass767 pragma argument box production");
      Require_Syntax_Test
        ("token-cursor grammar distinguishes named positional and box pragma arguments",
         "pass767 pragma association depth regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "named, positional, and box pragma argument shapes",
         "pass767 matrix pragma argument association row");


      --  Pass768: qualified-expression selected subtype-mark depth.
      Require_Token_Cursor_Production
        ("Production_Qualified_Expression_Selected_Subtype_Mark",
         "pass768 selected qualified-expression subtype-mark production");
      Require_Syntax_Test
        ("selected subtype marks must be retained distinctly for qualified-expression consumers",
         "pass768 selected qualified-expression subtype-mark regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "selected subtype marks in qualified expressions",
         "pass768 matrix selected qualified-expression subtype-mark row");

      --  Pass769: package/subprogram body declarative recovery depth.
      Require_Token_Cursor_Production
        ("Production_Package_Body_Declarative_Recovery_Boundary",
         "pass769 package body declarative recovery production");
      Require_Token_Cursor_Production
        ("Production_Subprogram_Body_Declarative_Recovery_Boundary",
         "pass769 subprogram body declarative recovery production");
      Require_Syntax_Test
        ("token-cursor grammar synchronizes malformed body declarative items",
         "pass769 body declarative recovery regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "body declarative recovery boundaries",
         "pass769 matrix body declarative recovery row");

      --  Pass770: protected anonymous access-to-subprogram profile depth.
      Require_Token_Cursor_Production
        ("Production_Access_Protected_Subprogram_Definition",
         "pass770 protected access-to-subprogram production");
      Require_Token_Cursor_Production
        ("Production_Access_Protected_Procedure_Profile",
         "pass770 protected access-to-procedure profile production");
      Require_Token_Cursor_Production
        ("Production_Access_Protected_Function_Profile",
         "pass770 protected access-to-function profile production");
      Require_Syntax_Test
        ("token-cursor grammar deepens protected anonymous access-to-subprogram profiles",
         "pass770 protected anonymous access profile regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "protected procedure/function profile markers",
         "pass770 matrix protected anonymous access profile row");

      --  Pass774: allocator constraint metadata depth.
      Require_Token_Cursor_Production
        ("Production_Allocator_Null_Exclusion",
         "pass774 allocator null-exclusion production");
      Require_Token_Cursor_Production
        ("Production_Allocator_Index_Constraint",
         "pass774 allocator index constraint production");
      Require_Token_Cursor_Production
        ("Production_Allocator_Discriminant_Constraint",
         "pass774 allocator discriminant constraint production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Allocator_Constraint_Depth_Pass774",
         "pass774 allocator constraint metadata regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Pass774 allocator constraint metadata depth",
         "pass774 matrix allocator constraint metadata row");

      --  Pass775: renaming-specific aspect placement depth.
      Require_Token_Cursor_Production
        ("Production_Renaming_Aspect_Specification",
         "pass775 renaming aspect-placement production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Renaming_Aspect_Placement_Pass775",
         "pass775 renaming aspect placement regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Pass775 renaming aspect placement depth",
         "pass775 matrix renaming aspect placement row");


      --  Pass776: generic formal type edge-depth recovery/ancestor metadata.
      Require_Token_Cursor_Production
        ("Production_Formal_Scalar_Box_Recovery_Boundary",
         "pass776 formal scalar box recovery production");
      Require_Token_Cursor_Production
        ("Production_Formal_Derived_Interface_List",
         "pass776 formal derived interface-list production");
      Require_Token_Cursor_Production
        ("Production_Formal_Interface_Ancestor_List",
         "pass776 formal interface ancestor-list production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Generic_Formal_Type_Edge_Depth_Pass776",
         "pass776 generic formal type edge-depth regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Pass776 generic formal type edge depth",
         "pass776 matrix generic formal type edge-depth row");

      --  Pass777: attribute-definition clause detail-depth metadata.
      Require_Token_Cursor_Production
        ("Production_Size_Attribute_Definition_Clause",
         "pass777 size attribute-definition production");
      Require_Token_Cursor_Production
        ("Production_Alignment_Attribute_Definition_Clause",
         "pass777 alignment attribute-definition production");
      Require_Token_Cursor_Production
        ("Production_External_Tag_Attribute_Definition_Clause",
         "pass777 external-tag attribute-definition production");
      Require_Token_Cursor_Production
        ("Production_Storage_Attribute_Definition_Clause",
         "pass777 storage attribute-definition production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Attribute_Definition_Detail_Pass777",
         "pass777 attribute-definition detail regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Pass777 attribute-definition clause detail depth",
         "pass777 matrix attribute-definition detail row");


      --  Pass778: protected body operation-body metadata.
      Require_Token_Cursor_Production
        ("Production_Protected_Procedure_Body",
         "pass778 protected procedure body production");
      Require_Token_Cursor_Production
        ("Production_Protected_Function_Body",
         "pass778 protected function body production");
      Require_Token_Cursor_Production
        ("Production_Protected_Entry_Body",
         "pass778 protected entry body production");
      Require_Token_Cursor_Production
        ("Production_Protected_Entry_Barrier_Condition",
         "pass778 protected entry barrier condition production");
      Require_Syntax_Test
        ("Test_Language_Model_Token_Cursor_Protected_Body_Operation_Depth_Pass778",
         "pass778 protected body operation-depth regression");
      Require_Marker
        ("docs/ada_parser_coverage_matrix.md",
         "Pass778 protected body operation depth",
         "pass778 matrix protected body operation-depth row");
   end Check_Recent_Grammar_Pass_Guards;

   procedure Check_Architecture is
   begin
      Require_Marker (Outline_Source, "Editor.Ada_Declaration_Parser.Parse", "parser-backed Outline");
      Require_Marker (Outline_Source, "Append_Analysis_Result", "language-model Outline projection");
      Require_Marker (Outline_Source, "Append_Marker_Source_Line", "manual Outline marker fallback");
      Require_Marker (Outline_Source, "Parser produced no Ada symbols", "marker-only fallback documentation");
      Require_Marker ("src/core/editor-executor.adb", "Same_Target_Path", "normalized indexed navigation execution");
      Require_Marker ("src/core/editor-executor.adb", "Pass 202: target-key validation already normalizes", "normalized indexed navigation execution");
      Forbid_Marker (Outline_Source, "procedure Append_Ada_Line", "legacy Outline scanner");
      Forbid_Marker (Outline_Source, "Append_Source_Line", "legacy Outline scanner");
      Forbid_Marker (Outline_Source, "Append_Ada_Line (Result, State", "legacy Outline scanner");
      Forbid_Marker (Outline_Source, "Ada_Like", "extension-gated Outline parsing");

      Require_Marker (Semantics_Source, "Build_Map_From_Analysis", "language-model semantic colouring");
      Require_Marker (Semantics_Source, "Kind_For_Identifier_In_Scope", "scope-aware semantic lookup");
      Require_Marker (Semantics_Source, "Editor.Ada_Symbol_Resolver.Resolve_In_Scope", "resolver-backed semantic lookup");
      Require_Marker (Semantics_Source, "Editor.Ada_Language_Model.Kind_To_Syntax_Kind", "language-model semantic kind mapping");

      Require_Marker (Token_Cursor_Spec, "type Cursor is private", "token-cursor Ada grammar architecture");
      Require_Marker (Token_Cursor_Spec, "Production_Compilation_Unit", "token-cursor Ada grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_With_Clause", "token-cursor with-clause grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Limited_With_Clause", "token-cursor limited with-clause grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Private_With_Clause", "token-cursor private with-clause grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Use_Clause", "token-cursor ordinary use-clause grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Use_Type_Clause", "token-cursor use-type grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Use_All_Type_Clause", "token-cursor use-all-type grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Use_Package_Name", "token-cursor ordinary use package-name grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Use_Type_Subtype_Mark", "token-cursor use-type subtype-mark grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Expression", "token-cursor expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Membership_Choice_List", "token-cursor membership-choice grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Target_Name", "token-cursor Ada 2022 target-name grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Box_Expression", "token-cursor Ada box-expression grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Short_Circuit_Operation", "token-cursor short-circuit expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Allocator", "token-cursor allocator expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Delta_Aggregate", "token-cursor delta-aggregate expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Positional_Component", "token-cursor aggregate positional-component grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Named_Component_Association", "token-cursor aggregate named-association grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Others_Choice", "token-cursor aggregate others-choice grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Null_Record_Aggregate", "token-cursor null-record aggregate grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Recovery_Boundary", "token-cursor aggregate recovery-boundary grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Reduction_Expression", "token-cursor reduction expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Attribute_Argument_Part", "token-cursor attribute argument-part grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Attribute_Designator_Name", "token-cursor attribute designator-name grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Classwide_Attribute_Reference", "token-cursor class-wide attribute-reference grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Attribute_Argument_Association", "token-cursor attribute argument-association grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Attribute_Recovery_Boundary", "token-cursor attribute recovery-boundary grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Part", "token-cursor detailed declaration grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Parameter_Mode", "token-cursor structured parameter mode grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Aliased_Part", "token-cursor structured aliased profile grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Default_Expression", "token-cursor structured profile default grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Record_Definition", "token-cursor record grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Incomplete_Type_Declaration", "token-cursor incomplete type grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Tagged_Incomplete_Type_Declaration", "token-cursor tagged incomplete type grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Conditional_Expression", "token-cursor Ada 2012 expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Extended_Return_Statement", "token-cursor complete statement grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Labeled_Statement", "token-cursor label grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Subunit", "token-cursor separate subunit grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Subprogram_Body_Stub", "token-cursor body-stub grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Task_Type_Declaration", "token-cursor task type grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Task_Definition", "token-cursor task-definition grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Protected_Type_Declaration", "token-cursor protected type grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Protected_Definition", "token-cursor protected-definition grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Entry_Family_Definition", "token-cursor entry-family grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Entry_Index_Specification", "token-cursor entry-index grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Entry_Barrier", "token-cursor entry-barrier grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Select_Alternative", "token-cursor alternative grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Loop_Parameter_Specification", "token-cursor loop-parameter grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Iterator_Specification", "token-cursor iterator-loop grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Array_Type_Definition", "token-cursor array type-definition grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Index_Subtype_Definition", "token-cursor unconstrained array index subtype grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Access_Type_Definition", "token-cursor access type-definition grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Null_Exclusion", "token-cursor null-exclusion access grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Range_Constraint", "token-cursor subtype/range constraint grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Range_Expression", "token-cursor range expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Range_Lower_Bound", "token-cursor range lower-bound grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Range_Upper_Bound", "token-cursor range upper-bound grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Range_Attribute_Reference", "token-cursor range attribute-reference grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Index_Constraint_Item", "token-cursor index-constraint item grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Constraint_Recovery_Boundary", "token-cursor constraint recovery-boundary grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Discrete_Choice_List", "token-cursor discrete choice-list grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Discrete_Choice", "token-cursor discrete choice grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Case_Choice_List", "token-cursor case statement choice-list grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Case_Choice_Arrow", "token-cursor case statement choice-arrow grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Case_Alternative_Recovery_Boundary", "token-cursor case statement recovery-boundary grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Variant_Choice_Arrow", "token-cursor variant choice arrow grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Variant_Others_Choice", "token-cursor variant others choice grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Nested_Variant_Part", "token-cursor nested variant part grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Variant_Recovery_Boundary", "token-cursor variant recovery boundary grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Slice", "token-cursor slice grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Explicit_Dereference", "token-cursor explicit dereference grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Pragma_Argument_Association", "token-cursor pragma argument grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Aspect_Association", "token-cursor aspect association grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Contract_Aspect_Association", "token-cursor contract aspect association grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Global_Aspect_Expression", "token-cursor Global aspect expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Depends_Aspect_Expression", "token-cursor Depends aspect expression grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Visible_Part", "token-cursor package visible part grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Private_Declarative_Item", "token-cursor package private item grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Body_Declarative_Item", "token-cursor package body declarative item grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Association", "token-cursor generic actual grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Object_Declaration", "token-cursor formal object grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Type_Declaration", "token-cursor formal type grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Subprogram_Declaration", "token-cursor formal subprogram grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Declaration", "token-cursor formal package grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Generic_Name", "token-cursor formal package generic-name grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Missing_Generic_Name", "token-cursor formal package missing generic-name recovery productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Defaulted_Actual_Part", "token-cursor defaulted formal package actual-part grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Actual_Part", "token-cursor formal package actual-part grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Actual_Box", "token-cursor formal package box actual grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Actual_Empty_Recovery_Boundary", "token-cursor formal package empty actual recovery productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Nested_Actual_Part", "token-cursor formal package nested actual grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Nested_Actual_Association", "token-cursor formal package nested association grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Actual_Missing_Arrow_Recovery_Boundary", "token-cursor formal package missing-arrow recovery grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Missing_Is_Recovery_Boundary", "token-cursor formal package missing-is recovery grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Missing_New_Recovery_Boundary", "token-cursor formal package missing-new recovery grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Missing_Generic_Recovery_Boundary", "token-cursor formal package missing-generic recovery grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Named_To_Positional_Order_Recovery_Boundary", "token-cursor formal package named-to-positional recovery grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Package_Actual_Recovery_Boundary", "token-cursor formal package recovery boundary grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Renaming_Declaration", "token-cursor package renaming grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Subprogram_Renaming_Declaration", "token-cursor subprogram renaming grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Object_Renaming_Declaration", "token-cursor object renaming grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Renaming_Declaration", "token-cursor exception renaming grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Package_Renaming_Declaration", "token-cursor generic package renaming grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Subprogram_Renaming_Declaration", "token-cursor generic subprogram renaming grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renamed_Entity", "token-cursor renamed-entity grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renamed_Object_Name", "token-cursor renamed object target grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renamed_Package_Name", "token-cursor renamed package target grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renamed_Subprogram_Name", "token-cursor renamed subprogram target grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renamed_Generic_Unit_Name", "token-cursor renamed generic unit target grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renamed_Selected_Target", "token-cursor selected renamed target grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renamed_Operator_Target", "token-cursor operator renamed target grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Renaming_Recovery_Boundary", "token-cursor renaming recovery boundary grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Abstract_Subprogram_Declaration", "token-cursor abstract subprogram grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Null_Procedure_Declaration", "token-cursor null procedure grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Expression_Function_Declaration", "token-cursor expression function grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Overriding_Indicator", "token-cursor overriding indicator grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Subprogram_Default", "token-cursor defaulted formal subprogram grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Defining_Name", "token-cursor defining-name grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Defining_Operator_Symbol", "token-cursor defining operator-symbol grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Attribute_Definition_Clause", "token-cursor attribute definition-clause grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Enumeration_Representation_Clause", "token-cursor enumeration representation-clause grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Address_Clause", "token-cursor address-clause grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Representation_Component_Clause", "token-cursor representation component grammar productions");
      Require_Marker (Token_Cursor_Body, "Parse_Declaration_Or_Statement", "token-cursor declaration/statement grammar entry point");
      Require_Marker (Token_Cursor_Body, "Parse_Context_Clause", "token-cursor context-clause grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Limited_With_Clause", "token-cursor limited with-clause grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Private_With_Clause", "token-cursor private with-clause grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Simple_Expression", "token-cursor expression precedence grammar");
      Require_Marker (Token_Cursor_Body, "Production_Membership_Choice", "token-cursor membership-choice grammar implementation");
      Require_Marker (Token_Cursor_Body, "target name", "token-cursor Ada 2022 target-name implementation");
      Require_Marker (Token_Cursor_Body, "Production_Raise_Expression", "token-cursor raise-expression grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Reduction_Expression", "token-cursor reduction-expression grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Discriminant_Part", "token-cursor discriminant grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Record_Definition", "token-cursor record/variant grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Discrete_Choice_List", "token-cursor discrete choice-list grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Discrete_Choice", "token-cursor discrete choice grammar implementation");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Discrete_Choice_Grammar_Completeness", "token-cursor discrete choice grammar test coverage");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Case_Statement_Choice_Depth_Grammar_Completeness", "token-cursor case statement choice depth test coverage");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Range_Constraint_Depth_Grammar_Completeness", "token-cursor range/index constraint depth test coverage");
      Require_Marker (Token_Cursor_Body, "Is_Statement_Starter_After_Label", "token-cursor statement-identifier disambiguation");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Statement_Identifier_Grammar_Completeness", "token-cursor statement identifier grammar test coverage");
      Require_Marker (Token_Cursor_Body, "Production_Selected_Name", "token-cursor selected-name grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parenthesized_Name_Suffix_Is_Slice", "token-cursor slice grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Explicit_Dereference", "token-cursor explicit dereference grammar implementation");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Name_Target_Grammar_Completeness", "token-cursor name-target grammar test coverage");
      Require_Marker (Token_Cursor_Body, "Production_Extended_Return_Statement", "token-cursor extended-return grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Entry_Call_Statement", "token-cursor entry-call grammar implementation");
      Require_Marker (Token_Cursor_Spec, "Production_Statement_Name_Suffix", "token-cursor statement name suffix grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Assignment_Selected_Target", "token-cursor selected assignment target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Assignment_Indexed_Target", "token-cursor indexed assignment target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Assignment_Slice_Target", "token-cursor slice assignment target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Assignment_Dereference_Target", "token-cursor dereference assignment target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Call_Selected_Target", "token-cursor selected call target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Call_Actual_Association", "token-cursor call actual association grammar production");
      Require_Marker (Token_Cursor_Body, "Add_Statement_Name_Suffix_Productions", "token-cursor assignment and call target suffix classification");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Assignment_Call_Ambiguity_Grammar_Completeness", "token-cursor assignment call ambiguity grammar depth");
      Require_Marker (Token_Cursor_Body, "Production_Task_Definition", "token-cursor task-definition grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Protected_Definition", "token-cursor protected-definition grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Entry_Family_Definition", "token-cursor entry-family grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Entry_Index_Specification", "token-cursor entry-index grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Task_Type_Declaration", "token-cursor task type grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Protected_Type_Declaration", "token-cursor protected type grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Entry_Parenthesized_Parts", "token-cursor entry parenthesized-part grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Entry_Barrier", "token-cursor entry-barrier grammar implementation");
      Require_Marker (Token_Cursor_Spec, "Production_Protected_Operation_Declaration", "token-cursor protected operation grammar productions");
      Require_Marker (Token_Cursor_Spec, "Production_Entry_Family_Index_Subtype", "token-cursor entry-family index subtype grammar productions");
      Require_Marker (Token_Cursor_Body, "Production_Accept_Do_Part", "token-cursor accept do-part grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Select_Or_Alternative", "token-cursor select-or alternative grammar implementation");
      Require_Marker (Token_Cursor_Spec, "Production_Select_Entry_Call_Alternative", "token-cursor select entry-call alternative grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Timed_Entry_Call_Alternative", "token-cursor timed entry-call alternative grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Conditional_Entry_Call_Alternative", "token-cursor conditional entry-call alternative grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Select_Delay_Alternative", "token-cursor select delay/terminate alternative grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Entry_Call_Entry_Name", "token-cursor entry-call name grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Entry_Call_Index", "token-cursor entry-call index grammar production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Task_Protected_Deep_Grammar_Pass", "token-cursor task/protected deep grammar test coverage");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Entry_Select_Depth_Grammar_Completeness", "token-cursor entry/select depth grammar test coverage");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Profile_Parameter", "profile parameter legality diagnostic kind");
      Require_Marker (Parser_Body, "Profile_Parameter_Duplicate", "profile parameter duplicate legality helper");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Legality_Profile_Parameter_Pass", "profile parameter legality regression coverage");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Record_Component_Name", "record component duplicate diagnostic kind");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Discriminant_Name", "discriminant duplicate diagnostic kind");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Enumeration_Literal_Name", "enumeration literal duplicate diagnostic kind");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Generic_Formal_Name", "generic formal duplicate diagnostic kind");
      Require_Marker (Parser_Body, "Local declaration-family duplicates", "local duplicate declaration-family legality pass");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Legality_Local_Duplicate_Declarations_Pass", "local duplicate declaration-family regression coverage");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Case_Choice", "case choice duplicate diagnostic kind");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Variant_Choice", "variant choice duplicate diagnostic kind");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Exception_Choice", "exception choice duplicate diagnostic kind");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Aggregate_Component_Choice", "aggregate component duplicate diagnostic kind");
      Require_Marker (Language_Model_Spec, "Legality_Duplicate_Delta_Aggregate_Component", "delta aggregate component duplicate diagnostic kind");
      Require_Marker (Parser_Body, "Choice_Count_In_List", "local duplicate choice legality helper");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Legality_Local_Duplicate_Choice_Pass", "local duplicate choice regression coverage");

      Require_Marker (Token_Cursor_Body, "Parse_Type_Definition", "token-cursor type-definition grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Subtype_Indication", "token-cursor subtype-indication grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Array_Index_Part", "token-cursor array index subtype grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Index_Subtype_Definition", "token-cursor unconstrained array index subtype grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Null_Exclusion", "token-cursor null-exclusion grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Null_Exclusion", "token-cursor null-exclusion grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Decimal_Fixed_Point_Definition", "token-cursor fixed-point type grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Pragma_Argument_List", "token-cursor pragma argument grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Representation_Clause", "token-cursor representation-clause grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Attribute_Definition_Clause", "token-cursor attribute definition-clause grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Attribute_Argument_List", "token-cursor attribute argument-list grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Enumeration_Representation_Clause", "token-cursor enumeration representation-clause grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Address_Clause", "token-cursor address-clause grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Aspect_Specification", "token-cursor aspect grammar implementation");
      Require_Marker (Token_Cursor_Body, "Is_Contract_Aspect_Mark", "token-cursor contract aspect grammar implementation");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Grammar_Completeness", "token-cursor contract aspect grammar test coverage");
      Require_Marker (Token_Cursor_Body, "Add_Package_Declaration_Part_Productions", "token-cursor package declaration part grammar implementation");
      Require_Marker (Token_Cursor_Body, "Skip_Package_Declarative_Item", "token-cursor bounded package item recovery implementation");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Completeness", "token-cursor package declarative item test coverage");
      Require_Marker (Token_Cursor_Body, "Production_Access_Subprogram_Profile", "token-cursor anonymous access-to-subprogram profile grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Access_Subprogram_Result_Profile", "token-cursor anonymous access-to-function result profile grammar implementation");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Grammar_Completeness", "token-cursor anonymous access-to-subprogram grammar test coverage");
      Require_Marker (Token_Cursor_Body, "Production_Access_Subprogram_Parameter_Default", "token-cursor anonymous access-to-subprogram parameter default grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Access_Subprogram_Result_Constraint", "token-cursor anonymous access-to-subprogram result constraint grammar implementation");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Edge_Recovery", "token-cursor anonymous access-to-subprogram edge recovery test coverage");
      Require_Marker (Token_Cursor_Body, "Parse_Attached_Aspect_Or_Semicolon", "token-cursor attached aspect semicolon placement implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Attached_Aspect_Before_Keyword_Or_Semicolon", "token-cursor attached aspect before body keyword placement implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Generic_Actual_Part", "token-cursor generic actual grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Generic_Formal_Declaration", "token-cursor generic formal grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Subprogram_Construct", "token-cursor subprogram modifier grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Renaming_Tail", "token-cursor renaming declaration grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Defining_Program_Unit_Name", "token-cursor defining program-unit renaming-name grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Generic_Renaming_Declaration", "token-cursor generic renaming declaration grammar implementation");
      Require_Marker (Token_Cursor_Body, "Production_Subprogram_Default", "token-cursor formal subprogram default implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Defining_Name", "token-cursor defining-name parser implementation");
      Require_Marker (Token_Cursor_Body, "Production_Defining_Operator_Symbol", "token-cursor operator-symbol parser implementation");
      Require_Marker (Token_Cursor_Body, "Production_Formal_Derived_Type_Definition", "token-cursor formal derived type grammar implementation");
      Require_Marker (Token_Cursor_Body, "Parse_Record_Representation_Clause", "token-cursor record representation grammar implementation");
      Require_Marker (Syntax_Tree_Body, "Attach_Token_Cursor_Grammar", "syntax-tree token-cursor grammar consumption");
      Require_Marker (Syntax_Tree_Spec, "Node_Token_Cursor_Grammar", "syntax-tree token-cursor grammar ownership");

      Require_Marker ("src/core/editor-commands.adb", "return ""outline.refresh""", "canonical Outline command surface");
      Require_Marker ("src/core/editor-commands.adb", "return ""outline.clear""", "canonical Outline command surface");
      Require_Marker ("src/core/editor-commands.adb", "return ""outline.show""", "canonical Outline command surface");
      Require_Marker ("src/core/editor-commands.adb", "return ""outline.focus""", "canonical Outline command surface");
      Require_Marker ("src/core/editor-commands.adb", "return ""outline.open-selected""", "canonical Outline command surface");
   end Check_Architecture;

   procedure Check_Parser_And_Model_Features is
   begin
      Require_Marker (Language_Model_Spec, "Has_Representation_Clause", "representation-clause metadata");
      Require_Marker (Language_Model_Spec, "Has_Aspect_Specification", "aspect-specification metadata");
      Require_Marker (Language_Model_Spec, "Mark_Symbol_Aspect_Specification", "split aspect metadata mutator");
      Require_Marker (Language_Model_Spec, "Has_Pragma_Metadata", "pragma metadata");
      Require_Marker (Language_Model_Spec, "Has_Null_Exclusion", "null-exclusion metadata");
      Require_Marker (Language_Model_Spec, "Has_Aliased_Metadata", "aliased declaration metadata");
      Require_Marker (Language_Model_Spec, "Has_Limited_Metadata", "limited type metadata");
      Require_Marker (Language_Model_Spec, "Has_Tagged_Metadata", "tagged type metadata");
      Require_Marker (Language_Model_Spec, "Has_Interface_Metadata", "interface type metadata");
      Require_Marker (Language_Model_Spec, "Has_Synchronized_Metadata", "synchronized interface metadata");
      Require_Marker (Language_Model_Spec, "Has_Task_Interface_Metadata", "task interface metadata");
      Require_Marker (Language_Model_Spec, "Has_Protected_Interface_Metadata", "protected interface metadata");
      Require_Marker (Language_Model_Spec, "Has_Task_Type_Metadata", "task type metadata");
      Require_Marker (Language_Model_Spec, "Has_Protected_Type_Metadata", "protected type metadata");
      Require_Marker (Language_Model_Spec, "Has_Access_Metadata", "access declaration-form metadata");
      Require_Marker (Language_Model_Spec, "Has_Access_All_Metadata", "access-all declaration-form metadata");
      Require_Marker (Language_Model_Spec, "Has_Access_Constant_Metadata", "access-constant declaration-form metadata");
      Require_Marker (Language_Model_Spec, "Has_Class_Wide_Metadata", "class-wide subtype-mark metadata");
      Require_Marker (Language_Model_Spec, "Has_Access_Subprogram_Metadata", "access-to-subprogram declaration-form metadata");
      Require_Marker (Language_Model_Spec, "Has_Access_Protected_Metadata", "access protected subprogram metadata");
      Require_Marker (Language_Model_Spec, "Has_Array_Metadata", "array declaration-form metadata");
      Require_Marker (Language_Model_Spec, "Has_Derived_Metadata", "derived type metadata");
      Require_Marker (Language_Model_Spec, "Has_Range_Metadata", "scalar range metadata");
      Require_Marker (Language_Model_Spec, "Has_Modular_Metadata", "modular type metadata");
      Require_Marker (Language_Model_Spec, "Has_Digits_Metadata", "digits type metadata");
      Require_Marker (Language_Model_Spec, "Has_Delta_Metadata", "delta fixed-point metadata");
      Require_Marker (Language_Model_Spec, "Has_Variant_Record_Metadata", "variant record metadata");
      Require_Marker (Language_Model_Spec, "Has_Default_Expression_Metadata", "default expression metadata");
      Require_Marker (Language_Model_Spec, "Has_Entry_Family_Metadata", "entry-family metadata");
      Require_Marker (Language_Model_Spec, "Has_Incomplete_Type_Metadata", "incomplete type metadata");
      Require_Marker (Language_Model_Spec, "Has_Profile_Mode_Metadata", "profile mode metadata");
      Require_Marker (Language_Model_Spec, "Has_Entry_Barrier_Metadata", "entry barrier metadata");
      Require_Marker (Language_Model_Spec, "Has_Box_Metadata", "box metadata");
      Require_Marker (Language_Model_Spec, "Has_Named_Number_Metadata", "named-number metadata");
      Require_Marker (Language_Model_Spec, "Has_Deferred_Constant_Metadata", "deferred-constant metadata");
      Require_Marker (Language_Model_Spec, "Has_Null_Subprogram_Metadata", "null-subprogram metadata");
      Require_Marker (Language_Model_Spec, "Has_Expression_Function_Metadata", "expression-function metadata");
      Require_Marker (Language_Model_Spec, "Has_Null_Record_Metadata", "null-record metadata");
      Require_Marker (Language_Model_Spec, "Has_Discriminant_Part_Metadata", "discriminant-part metadata");
      Require_Marker (Language_Model_Spec, "Has_Body_Stub_Metadata", "body-stub metadata");
      Require_Marker (Language_Model_Spec, "Has_Constraint_Metadata", "constraint metadata");
      Require_Marker (Language_Model_Spec, "Has_Child_Unit_Metadata", "child unit metadata");
      Require_Marker (Language_Model_Spec, "Has_Generic_Actual_Part_Metadata", "generic actual part metadata");
      Require_Marker (Language_Model_Spec, "Merge_Symbol_Flags", "syntax-tree-to-language-model metadata merge API");
      Require_Marker (Parser_Body, "Project_Syntax_Tree_Into_Model", "syntax-tree-to-language-model projection pass");
      Require_Marker (Parser_Body, "Syntax_Node_Symbol_Kind", "syntax-tree declaration kind projection");
      Require_Marker (Parser_Body, "Segment_First", "precise comma-separated visibility-name projection ranges");
      Require_Marker (Language_Model_Spec, "Is_Abstract", "abstract declaration metadata");
      Require_Marker (Language_Model_Spec, "Is_Overriding", "overriding indicator metadata");
      Require_Marker (Language_Model_Spec, "Is_Not_Overriding", "not-overriding indicator metadata");
      Require_Marker (Language_Model_Spec, "Has_With_Clause_Awareness", "with-clause awareness");
      Require_Marker (Language_Model_Spec, "Has_Use_Clause_Awareness", "use-clause awareness");
      Require_Marker (Language_Model_Spec, "Use_Clause_Count", "individual use-clause metadata projection");
      Require_Marker (Language_Model_Spec, "Use_Clause_At", "individual use-clause metadata access");
      Require_Marker (Language_Model_Spec, "Pragma_Placement_Kind", "pragma placement metadata model");
      Require_Marker (Language_Model_Spec, "Pragma_Metadata_Count", "pragma metadata projection access");
      Require_Marker (Language_Model_Spec, "Pragma_Metadata_At", "pragma metadata indexed access");
      Require_Marker (Parser_Body, "Pragma_Placement_For_Node", "syntax-tree pragma placement projection");
      Require_Marker (Parser_Body, "Pragma_Metadata_Named_Argument_Count", "pragma named argument metadata projection");
      Require_Marker (Language_Model_Spec, "Representation_Source_Form", "representation source-form metadata model");
      Require_Marker (Language_Model_Spec, "Representation_Source_Record_Component_Clause", "record component representation source metadata");
      Require_Marker (Parser_Body, "Clause_Source_Form", "representation clause source-form projection");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Formal_Aspect_Specification", "generic formal aspect placement production");
      Require_Marker (Token_Cursor_Spec, "Production_Concurrent_Type_Aspect_Specification", "concurrent type aspect placement production");
      Require_Marker (Token_Cursor_Spec, "Production_Entry_Aspect_Specification", "entry aspect placement production");
      Require_Marker (Token_Cursor_Spec, "Production_Protected_Operation_Aspect_Attachment", "protected operation aspect placement production");
      Require_Marker (Token_Cursor_Spec, "Production_Body_Stub_Aspect_Specification", "body-stub aspect placement production");
      Require_Marker (Token_Cursor_Spec, "Production_Private_Completion_Aspect_Specification", "private completion aspect placement production");
      Require_Marker (Token_Cursor_Spec, "Production_Body_Aspect_Specification", "body aspect placement production");
      Require_Marker (Language_Model_Spec, "Statement_Kind", "statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_For_In_Loop", "for-in loop statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_For_Of_Loop", "for-of loop statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_For_Reverse_Loop", "reverse for-loop statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Exception_Handler", "exception statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Begin_Action", "same-line begin action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Declare_Action", "same-line declare action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Label", "statement label awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Named_Block", "named block statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Named_Loop", "named loop statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Entry_Call", "conditional entry-call select statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Action", "conditional entry-call select else-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Null", "conditional entry-call select else-null statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Return", "conditional entry-call select else-return statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Raise", "conditional entry-call select else-raise statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Assignment", "conditional entry-call select else-assignment statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Call", "conditional entry-call select else-call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Code", "conditional entry-call select else-code statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Exit", "conditional entry-call select else-exit statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Goto", "conditional entry-call select else-goto statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Delay", "conditional entry-call select else-delay statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Delay_Until", "conditional entry-call select else-delay-until statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Delay_Relative", "conditional entry-call select else-relative-delay statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Requeue", "conditional entry-call select else-requeue statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Requeue_With_Abort", "conditional entry-call select else-requeue-with-abort statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Abort", "conditional entry-call select else-abort statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Pragma", "conditional entry-call select else-pragma statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Else_Pragma_With_Arguments", "conditional entry-call select else-pragma-arguments statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback", "timed entry-call select delay-fallback statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Action", "timed entry-call select delay-fallback action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Null", "timed entry-call select delay-fallback null-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Call", "timed entry-call select delay-fallback call-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Call_With_Arguments", "timed entry-call select delay-fallback argument-call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Call_With_Named_Association", "timed entry-call select delay-fallback named-association call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Call_Selected_Name", "timed entry-call select delay-fallback selected-call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Call_Access_Dereference", "timed entry-call select delay-fallback access-call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Call_Entry_Family_Index", "timed entry-call select delay-fallback entry-family call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Assignment", "timed entry-call select delay-fallback assignment-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Return", "timed entry-call select delay-fallback return-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Raise", "timed entry-call select delay-fallback raise-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Code", "timed entry-call select delay-fallback code-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Exit", "timed entry-call select delay-fallback exit-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Goto", "timed entry-call select delay-fallback goto-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Delay", "timed entry-call select delay-fallback delay-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Requeue", "timed entry-call select delay-fallback requeue-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Abort", "timed entry-call select delay-fallback abort-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Pragma", "timed entry-call select delay-fallback pragma-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Delay_Fallback_Pragma_With_Arguments", "timed entry-call select delay-fallback pragma-argument statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Then_Abort_Fallback", "asynchronous select then-abort fallback statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Terminate_Fallback", "selective accept terminate fallback statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Select_Abortable_Call", "asynchronous select abortable call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Or_Alternative", "select-or statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Then_Abort_Alternative", "async-select then-abort statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Then_Abort_Action", "same-line then-abort action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Loop_Action", "same-line loop-body action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Case_Alternative_Action", "same-line case alternative action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Exception_Handler_Action", "same-line exception handler action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Then_Action", "same-line if-then action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Goto_Label_Target", "goto label-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Elsif_Action", "same-line if-elsif action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Else_Action", "same-line if-else action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Terminate_Alternative", "select terminate statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Extended_Return", "extended return statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_End_Return", "structured end-return statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_End_Block", "anonymous block terminator statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Accept_Alternative", "same-line selective accept alternative statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Accept_Body", "accept-body statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Accept_With_Profile", "accept-profile statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Accept_Entry_Family_Index", "accept entry-family statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Delay_Until", "delay-until statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Delay_Relative", "relative delay statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Delay_Alternative", "selective-accept delay alternative statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Delay_Alternative_Until", "delay-until alternative statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Delay_Alternative_Relative", "relative delay alternative statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Exit_When", "conditional exit statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Exit_Named_Loop", "named-loop exit statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Raise_Reraise", "reraise statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Raise_Exception_Name", "raise exception-name statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Raise_With_Message", "raise-with-message statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Requeue_With_Abort", "requeue-with-abort statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Requeue_Selected_Target", "selected requeue-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Requeue_With_Arguments", "requeue argument target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Call_With_Arguments", "procedure-call argument awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Call_With_Named_Association", "procedure-call named-association awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Call_Selected_Name", "selected-name call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Call_Access_Dereference", "access-dereference call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Call_Attribute_Name", "attribute-name call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Call_Entry_Family_Index", "entry-family call statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Null_Alternative", "null alternative statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Raise", "alternative raise-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Return", "alternative return-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Return_With_Expression", "return-expression statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Return_With_Expression", "alternative return-expression statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Assignment", "alternative assignment-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Assignment_Selected_Target", "selected assignment-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Assignment_Indexed_Target", "indexed assignment-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Assignment_Slice_Target", "slice assignment-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Assignment_Access_Dereference", "access-dereference assignment-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Call", "alternative call-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Exit", "alternative exit-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Goto", "alternative goto-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Delay", "alternative delay-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Requeue", "alternative requeue-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Abort", "alternative abort-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Abort_Selected_Target", "selected abort-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Abort_Multiple_Targets", "multiple abort-target statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Code", "alternative code-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Code", "Ada code-statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Pragma", "pragma statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Pragma_With_Arguments", "pragma argument statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Alternative_Pragma", "alternative pragma-action statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_End_If", "structured end-if statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_End_Case", "structured end-case statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_End_Loop", "structured end-loop statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_End_Named_Loop", "named end-loop statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_End_Select", "structured end-select statement awareness model");
      Require_Marker (Language_Model_Spec, "Statement_Count", "statement awareness query API");
      Require_Marker (Language_Model_Spec, "Has_Statement_Awareness", "statement awareness query API");
      Require_Marker (Language_Model_Spec, "Set_Syntax_Tree", "syntax tree ownership API");
      Require_Marker (Language_Model_Spec, "Has_Syntax_Tree", "syntax tree query API");
      Require_Marker (Language_Model_Spec, "Syntax_Tree_Node_Count", "syntax tree node-count API");
      Require_Marker (Language_Model_Spec, "Syntax_Tree_Root_Kind", "syntax tree root-kind API");
      Require_Marker (Syntax_Tree_Spec, "type Node_Kind is", "Ada syntax tree node model");
      Require_Marker (Syntax_Tree_Spec, "Node_Compilation_Unit", "Ada syntax tree compilation-unit root");
      Require_Marker (Syntax_Tree_Spec, "Node_Pragma_Name", "Ada syntax tree pragma name nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Pragma_Argument", "Ada syntax tree pragma argument nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Pragma_Argument_Association", "Ada syntax tree named pragma argument nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Aspect_Specification", "Ada syntax tree aspect specification nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Aspect_Association", "Ada syntax tree aspect association nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Aspect_Name", "Ada syntax tree aspect name child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Aspect_Value", "Ada syntax tree aspect value child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Representation_Clause", "Ada syntax tree representation clause nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Representation_Target", "Ada syntax tree representation target nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Representation_Item", "Ada syntax tree representation item nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Representation_Component_Clause", "Ada syntax tree record representation component clause nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Generic_Actual_Part", "Ada syntax tree generic actual part nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Generic_Actual_Association", "Ada syntax tree generic actual association nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Generic_Actual_Formal", "Ada syntax tree generic actual formal child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Generic_Actual_Value", "Ada syntax tree generic actual value child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Abstract_Subprogram_Declaration", "Ada syntax tree abstract subprogram declaration nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Null_Procedure_Declaration", "Ada syntax tree null procedure declaration nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Expression_Function_Declaration", "Ada syntax tree expression function declaration nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Formal_Type_Declaration", "Ada syntax tree generic formal type declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Formal_Subprogram_Declaration", "Ada syntax tree generic formal subprogram declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Formal_Object_Declaration", "Ada syntax tree generic formal object declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Formal_Package_Declaration", "Ada syntax tree generic formal package declarations");
      Require_Marker (Syntax_Tree_Body, "with package P is new G (A => B, others => <>);", "formal package actual projection parser path");
      Require_Marker (Resolver_Body, "Inst.Kind /= Symbol_Generic_Formal_Package", "formal package selected generic-template resolver view");
      Require_Marker (Syntax_Tree_Spec, "Node_Incomplete_Type_Declaration", "Ada syntax tree incomplete type declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Private_Extension_Declaration", "Ada syntax tree private extension declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Constant_Declaration", "Ada syntax tree typed constant declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Deferred_Constant_Declaration", "Ada syntax tree deferred constant declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Number_Declaration", "Ada syntax tree named-number declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Component_Declaration", "Ada syntax tree component declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Discriminant_Specification", "Ada syntax tree discriminant specifications");
      Require_Marker (Syntax_Tree_Spec, "Node_Task_Type_Declaration", "Ada syntax tree task type declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Single_Task_Declaration", "Ada syntax tree single task declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Protected_Type_Declaration", "Ada syntax tree protected type declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Single_Protected_Declaration", "Ada syntax tree single protected declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Entry_Declaration", "Ada syntax tree entry declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Entry_Body", "Ada syntax tree entry body declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Entry_Body_Stub", "Ada syntax tree entry body stubs");
      Require_Marker (Syntax_Tree_Spec, "Node_Enumeration_Literal_Declaration", "Ada syntax tree enumeration literal declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Variant_Part", "Ada syntax tree record variant parts");
      Require_Marker (Syntax_Tree_Spec, "Node_Variant", "Ada syntax tree record variants");
      Require_Marker (Syntax_Tree_Spec, "Node_Declaration_Target", "Ada syntax tree renaming declaration target child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Private_Part", "Ada syntax tree private part nodes");
      Require_Marker (Syntax_Tree_Body, "when Node_Private_Part =>", "Ada syntax tree private parts are scope-aware");
      Require_Marker (Syntax_Tree_Body, "end private part", "Ada syntax tree private parts close structurally");
      Require_Marker (Syntax_Tree_Spec, "Node_Body_Stub", "Ada syntax tree body stub declarations");
      Require_Marker (Syntax_Tree_Spec, "Node_Declaration_Name", "Ada syntax tree declaration-name child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Declaration_Subtype", "Ada syntax tree declaration-subtype child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Declaration_Default", "Ada syntax tree declaration-default child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Declaration_Profile", "Ada syntax tree declaration-profile child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Declaration_Result", "Ada syntax tree declaration-result child nodes");
      Require_Marker (Syntax_Tree_Spec, "type Tree_Type is private", "Ada syntax tree owned tree type");
      Require_Marker (Syntax_Tree_Spec, "Node_Elsif_Part", "Ada syntax tree elsif alternative nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Else_Part", "Ada syntax tree else alternative nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_When_Alternative", "Ada syntax tree when alternative nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Select_Alternative", "Ada syntax tree select-or alternative nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Exception_Handler", "Ada syntax tree exception handler nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Exception_Section", "Ada syntax tree exception section nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Recovery_Point", "Ada syntax tree grammar recovery synchronization nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Implicit_Begin", "Ada syntax tree implicit begin recovery nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Unexpected_Declaration", "Ada syntax tree declaration-after-begin recovery nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Implicit_End", "Ada syntax tree implicit statement-part closure recovery nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Missing_End", "Ada syntax tree missing-end recovery nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Unexpected_End", "Ada syntax tree unexpected-end recovery nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Mismatched_End", "Ada syntax tree mismatched alternative/end recovery nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_End_Target", "Ada syntax tree named end-target detail nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Expected_End_Target", "Ada syntax tree expected named end-target recovery detail nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Expected_Token", "Ada syntax tree malformed-header expected-token recovery detail nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Expression", "Ada syntax tree expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Name", "Ada syntax tree name nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Selected_Name", "Ada syntax tree selected-name nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Attribute_Reference", "Ada syntax tree attribute-reference nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Function_Call", "Ada syntax tree function-call nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Operator_Expression", "Ada syntax tree operator-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Conditional_Expression", "Ada syntax tree conditional-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Case_Expression", "Ada syntax tree case-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Quantified_Expression", "Ada syntax tree quantified-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Declare_Expression", "Ada syntax tree declare-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Delta_Aggregate", "Ada syntax tree delta-aggregate nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Container_Aggregate", "Ada syntax tree container-aggregate nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Reduction_Expression", "Ada syntax tree reduction-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Iterator_Specification", "Ada syntax tree iterator-specification child nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Target_Name", "Ada syntax tree target-name expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Membership_Expression", "Ada syntax tree membership-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Short_Circuit_Expression", "Ada syntax tree short-circuit-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Unary_Expression", "Ada syntax tree unary-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Parenthesized_Expression", "Ada syntax tree parenthesized-expression nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Explicit_Dereference", "Ada syntax tree explicit-dereference nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Allocator", "Ada syntax tree allocator nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Named_Association", "Ada syntax tree named-association nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Positional_Association", "Ada syntax tree positional-association nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Exit_Statement", "Ada syntax tree exit statement nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Goto_Statement", "Ada syntax tree goto statement nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Requeue_Statement", "Ada syntax tree requeue statement nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Delay_Statement", "Ada syntax tree delay statement nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Abort_Statement", "Ada syntax tree abort statement nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Terminate_Statement", "Ada syntax tree terminate statement nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Entry_Call_Statement", "Ada syntax tree select entry-call statement nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Label", "Ada syntax tree label nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Statement_Sequence", "structured statement sequence nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Statement_Action", "structured statement action nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Statement_Alternative", "structured statement alternative nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Statement_Target", "structured statement target nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Statement_Condition", "structured statement condition nodes");
      Require_Marker (Syntax_Tree_Spec, "Node_Statement_Arguments", "structured statement argument nodes");
      Require_Marker (Syntax_Tree_Body, "function Parse", "Ada syntax tree parser foundation");
      Require_Marker (Syntax_Tree_Body, "Scope_Stack", "Ada syntax tree nested ownership stack");
      Require_Marker (Syntax_Tree_Body, "Opens_Scope", "Ada syntax tree source-shape scope tracking");
      Require_Marker (Syntax_Tree_Body, "Push_Scope", "Ada syntax tree child ownership push");
      Require_Marker (Syntax_Tree_Body, "Pop_Scope", "Ada syntax tree end-node scope pop");
      Require_Marker (Syntax_Tree_Body, "Is_Alternative_Node", "Ada syntax tree alternative scope tracking");
      Require_Marker (Syntax_Tree_Body, "Pop_Alternative_Scope", "Ada syntax tree sibling alternative ownership");
      Require_Marker (Syntax_Tree_Body, "Add_Expression_Nodes", "Ada syntax tree expression/name parsing");
      Require_Marker (Syntax_Tree_Body, "Node_Declare_Expression", "declare expressions are attached to expression nodes");
      Require_Marker (Syntax_Tree_Body, "Node_Delta_Aggregate", "delta aggregates are attached to expression nodes");
      Require_Marker (Syntax_Tree_Body, "Node_Container_Aggregate", "container aggregates are attached to expression nodes");
      Require_Marker (Syntax_Tree_Body, "Node_Reduction_Expression", "reduction expressions are attached to expression nodes");
      Require_Marker (Syntax_Tree_Body, "Node_Target_Name", "target-name expressions are attached to expression nodes");
      Require_Marker (Syntax_Tree_Body, "Add_Name_Tokens", "Ada syntax tree identifier-name parsing");
      Require_Marker (Syntax_Tree_Body, "Attach_Syntax_Details", "Ada syntax tree attaches expression/name children");
      Require_Marker (Syntax_Tree_Body, "Add_Structured_Statement_Node", "statement metadata converted into structured syntax-tree nodes");
      Require_Marker (Syntax_Tree_Body, "Attach_Statement_Details", "ordinary statements own structured details directly");
      Require_Marker (Syntax_Tree_Body, "Add_Action_Segment", "compact alternatives split into structured statement actions");
      Require_Marker (Syntax_Tree_Body, "Add_Action_Sequence", "compact statement sequence tree ownership");
      Require_Marker (Syntax_Tree_Body, "Add_Aspect_Specification_Nodes", "aspect specifications parse structurally");
      Require_Marker (Syntax_Tree_Body, "Add_Generic_Actual_Part_Nodes", "generic actual parts parse structurally");
      Require_Marker (Syntax_Tree_Body, "Add_Representation_Clause_Detail_Nodes", "representation clauses parse structurally");
      Require_Marker (Syntax_Tree_Body, "Add_Representation_Component_Clause_Detail_Nodes", "record representation component clauses parse structurally");
      Require_Marker (Syntax_Tree_Body, "Kind := Node_Representation_Component_Clause", "record representation component clauses are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "Recover_To_End_Boundary", "syntax tree performs grammar-aware end-boundary recovery");
      Require_Marker (Syntax_Tree_Body, "Recover_Alternative_Owner", "syntax tree performs grammar-aware alternative-owner recovery");
      Require_Marker (Syntax_Tree_Body, "Starts_Generic_Unit", "syntax tree closes generic formal parts at generic-unit boundaries");
      Require_Marker (Syntax_Tree_Body, "implicit close of generic formal part", "syntax tree emits generic formal-part implicit recovery nodes");
      Require_Marker (Syntax_Tree_Body, "Add_EOF_Recovery", "syntax tree inserts missing-end recovery nodes at EOF");
      Require_Marker (Syntax_Tree_Body, "Add_Declaration_Detail_Nodes", "Ada declaration forms parse with structured declaration children");
      Require_Marker (Syntax_Tree_Body, "Add_Discriminant_Nodes", "Ada discriminant parts parse structurally");
      Require_Marker (Syntax_Tree_Body, "Add_Enumeration_Literal_Nodes", "Ada enumeration literal declarations parse structurally");
      Require_Marker (Syntax_Tree_Body, "Kind := Node_Formal_Type_Declaration", "generic formal types are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "Kind := Node_Component_Declaration", "record components are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "Kind := Node_Variant_Part", "record variant parts are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "Kind := Node_Variant", "record variants are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "return Node_Abstract_Subprogram_Declaration", "abstract subprogram declarations are recognized structurally");
      Require_Marker (Syntax_Tree_Body, "return Node_Null_Procedure_Declaration", "null procedure declarations are recognized structurally");
      Require_Marker (Syntax_Tree_Body, "return Node_Expression_Function_Declaration", "expression function declarations are recognized structurally");
      Require_Marker (Syntax_Tree_Body, "Subprogram_Name_Text", "subprogram names parse before profile/default text");
      Require_Marker (Syntax_Tree_Body, "Subprogram_Profile_Text", "subprogram profiles parse into declaration child nodes");
      Require_Marker (Syntax_Tree_Body, "Subprogram_Result_Text", "function results parse into declaration child nodes");
      Require_Marker (Syntax_Tree_Body, "return Node_Body_Stub", "body stubs are recognized as declarations");
      Require_Marker (Syntax_Tree_Body, "return Node_Entry_Body", "entry bodies are recognized structurally");
      Require_Marker (Syntax_Tree_Body, "return Node_Entry_Body_Stub", "entry body stubs are recognized structurally");
      Require_Marker (Syntax_Tree_Body, "Node_Pragma_Argument", "pragma arguments parse structurally");
      Require_Marker (Syntax_Tree_Body, "triggering", "select then-abort triggering statement sequence retention");
      Require_Marker (Syntax_Tree_Body, "then abort", "select then-abort abortable statement sequence retention");
      Require_Marker (Syntax_Tree_Body, "return Node_Select_Alternative", "select alternatives keep structured node kind");
      Require_Marker (Syntax_Tree_Body, "Classified = Node_Else_Part", "line-level select else alternatives are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "Classified = Node_Terminate_Statement", "line-level select terminate alternatives are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "Kind := Node_Entry_Call_Statement", "line-level select entry calls are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "entry call", "select entry-call statement mode metadata");
      Require_Marker (Syntax_Tree_Body, "Classified = Node_When_Alternative", "line-level exception handlers are reclassified structurally");
      Require_Marker (Syntax_Tree_Body, "Current_Kind = Node_Exception_Section", "exception handlers are owned by exception sections");
      Require_Marker (Syntax_Tree_Body, "not Contains (L, "" end select"")", "same-line select scopes close without stale stack ownership");
      Require_Marker (Syntax_Tree_Body, "return Node_If_Statement", "compact embedded if actions keep structured node kind");
      Require_Marker (Syntax_Tree_Body, "return Node_Case_Statement", "compact embedded case actions keep structured node kind");
      Require_Marker (Syntax_Tree_Body, "return Node_Loop_Statement", "compact embedded loop actions keep structured node kind");
      Require_Marker (Syntax_Tree_Body, "return Node_Select_Statement", "compact embedded select actions keep structured node kind");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Expression_And_Name_Nodes", "syntax-tree expression/name regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Control_Statement_Nodes", "syntax-tree control-statement regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Statement_Details_Are_Direct_Children", "direct statement-detail ownership regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Structured_Statement_Detail_Nodes", "structured statement-node regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Compact_Control_Actions_Are_Structured", "compact embedded control-flow statement regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Select_Then_Abort_Details", "select then-abort structured detail regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Select_Alternatives_Are_Structured", "select or/else alternative regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Line_Level_Select_Parts_Are_Structured", "line-level select then-abort/else/terminate regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Exception_Handlers_Are_Structured", "first-class exception handler syntax-tree regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Select_Entry_Calls_Are_Structured", "first-class select entry-call syntax-tree regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Syntax_Tree_Aspects_Pragmas_Representation_And_Generic_Actuals_Are_Structured", "aspect pragma representation and generic actual syntax-tree regression coverage");
      Require_Marker (Language_Model_Spec, "Has_Generated_Source_Awareness", "generated-source awareness");
      Require_Marker (Language_Model_Spec, "Has_Conditional_Source_Awareness", "conditional-source awareness");
      Require_Marker (Language_Model_Spec, "Set_Symbol_Kind", "split-declaration kind refinement");
      Require_Marker (Language_Model_Body, "Symbol_Separate_Body =>", "separate-body semantic kind mapping");
      Require_Marker (Parser_Body, "Parent_Symbol => Parent", "symbol parent retention");
      Require_Marker (Parser_Body, "Set_Syntax_Tree", "parser attaches syntax tree to analysis");
      Require_Marker (Parser_Body, "Editor.Ada_Syntax_Tree.Parse", "parser consumes syntax tree foundation");
      Require_Marker (Parser_Body, "Is_Scope_End", "balanced scope tracking");
      Require_Marker (Parser_Body, "Add_Discriminant_Names", "discriminant parsing");
      Require_Marker (Parser_Body, "Add_Record_Component_Names", "record component parsing");
      Require_Marker (Parser_Body, "Statement_End_If", "structured statement terminator parsing");
      Require_Marker (Parser_Body, "Add_Profile_Parameter_Names", "profile parameter parsing");
      Require_Marker (Parser_Body, "Symbol_Generic_Formal_Object", "generic formal object parsing");
      Require_Marker (Parser_Body, "Symbol_Generic_Formal_Type", "generic formal type parsing");
      Require_Marker (Parser_Body, "Final_Kind := Symbol_Separate_Body", "separate-body parsing");
      Require_Marker (Parser_Body, "Mark_Representation_Clause_Target", "representation-clause target binding");
      Require_Marker (Parser_Body, "Has_Aspect_Specification", "aspect-specification detection");
      Require_Marker (Parser_Body, "Pending_Aspect_Owner", "split aspect continuation ownership");
      Require_Marker (Parser_Body, "Statement_When_Alternative", "executable when-alternative statement awareness");
      Require_Marker (Parser_Body, "Strip_Leading_Statement_Labels", "labelled statement normalization");
      Require_Marker (Parser_Body, "Leading_Statement_Label_Count", "stacked labelled statement counting");
      Require_Marker (Parser_Body, "Mark_Leading_Statement_Labels", "stacked labelled statement metadata emission");
      Require_Marker (Parser_Body, "Strip_Leading_Named_Statement_Prefix", "named block/loop statement normalization");
      Require_Marker (Parser_Body, "Statement_Label", "statement label awareness");
      Require_Marker (Parser_Body, "Statement_Named_Block", "named block statement awareness");
      Require_Marker (Parser_Body, "Statement_Named_Loop", "named loop statement awareness");
      Require_Marker (Parser_Body, "Statement_Exception_Handler", "exception-section statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Entry_Call", "conditional entry-call select statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Action", "conditional entry-call select else-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Null", "conditional entry-call select else-null statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Return", "conditional entry-call select else-return statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Raise", "conditional entry-call select else-raise statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Assignment", "conditional entry-call select else-assignment statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Call", "conditional entry-call select else-call statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Code", "conditional entry-call select else-code statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Exit", "conditional entry-call select else-exit statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Goto", "conditional entry-call select else-goto statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Delay", "conditional entry-call select else-delay statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Delay_Until", "conditional entry-call select else-delay-until statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Delay_Relative", "conditional entry-call select else-relative-delay statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Requeue", "conditional entry-call select else-requeue statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Requeue_With_Abort", "conditional entry-call select else-requeue-with-abort statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Abort", "conditional entry-call select else-abort statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Pragma", "conditional entry-call select else-pragma statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Else_Pragma_With_Arguments", "conditional entry-call select else-pragma-arguments statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback", "timed entry-call select delay-fallback statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Action", "timed entry-call select delay-fallback action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Null", "timed entry-call select delay-fallback null-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Call", "timed entry-call select delay-fallback call-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Call_With_Arguments", "timed entry-call select delay-fallback argument-call statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Call_With_Named_Association", "timed entry-call select delay-fallback named-association call statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Call_Selected_Name", "timed entry-call select delay-fallback selected-call statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Call_Access_Dereference", "timed entry-call select delay-fallback access-call statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Call_Entry_Family_Index", "timed entry-call select delay-fallback entry-family call statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Assignment", "timed entry-call select delay-fallback assignment-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Return", "timed entry-call select delay-fallback return-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Raise", "timed entry-call select delay-fallback raise-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Code", "timed entry-call select delay-fallback code-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Exit", "timed entry-call select delay-fallback exit-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Goto", "timed entry-call select delay-fallback goto-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Delay", "timed entry-call select delay-fallback delay-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Requeue", "timed entry-call select delay-fallback requeue-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Abort", "timed entry-call select delay-fallback abort-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Pragma", "timed entry-call select delay-fallback pragma-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Delay_Fallback_Pragma_With_Arguments", "timed entry-call select delay-fallback pragma-argument statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Then_Abort_Fallback", "asynchronous select then-abort fallback statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Terminate_Fallback", "selective accept terminate fallback statement awareness");
      Require_Marker (Parser_Body, "Statement_Select_Abortable_Call", "asynchronous select abortable call statement awareness");
      Require_Marker (Parser_Body, "Conditional entry-call statements", "conditional entry-call select parser comment");
      Require_Marker (Parser_Body, "Statement_Then_Abort_Action", "same-line then-abort action statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Loop_Action_Details", "same-line loop-body action statement awareness");
      Require_Marker (Parser_Body, "Statement_Loop_Action", "same-line loop-body action statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Case_Alternative_Details", "same-line case alternative action statement awareness");
      Require_Marker (Parser_Body, "Statement_Case_Alternative_Action", "same-line case alternative action statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Exception_Handler_Details", "same-line exception handler action statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Begin_Action_Details", "same-line begin action statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Declare_Action_Details", "same-line declare action statement awareness");
      Require_Marker (Parser_Body, "Statement_Exception_Handler_Action", "same-line exception handler action statement awareness");
      Require_Marker (Parser_Body, "Statement_Begin_Action", "same-line begin action statement awareness");
      Require_Marker (Parser_Body, "Statement_Declare_Action", "same-line declare action statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Then_Action_Details", "same-line if-then action statement awareness");
      Require_Marker (Parser_Body, "Statement_Then_Action", "same-line if-then action statement awareness");
      Require_Marker (Parser_Body, "Mark_Goto_Details", "goto label-target statement awareness");
      Require_Marker (Parser_Body, "Statement_Goto_Label_Target", "goto label-target statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Elsif_Action_Details", "same-line if-elsif action statement awareness");
      Require_Marker (Parser_Body, "Statement_Elsif_Action", "same-line if-elsif action statement awareness");
      Require_Marker (Parser_Body, "Mark_Compact_Else_Action_Details", "same-line if-else action statement awareness");
      Require_Marker (Parser_Body, "Statement_Else_Action", "same-line if-else action statement awareness");
      Require_Marker (Parser_Body, "Statement_Terminate_Alternative", "terminate-alternative statement awareness");
      Require_Marker (Parser_Body, "Statement_End_Select", "structured statement terminator awareness");
      Require_Marker (Parser_Body, "Statement_Extended_Return", "extended return statement awareness");
      Require_Marker (Parser_Body, "Statement_End_Return", "structured end-return statement awareness");
      Require_Marker (Parser_Body, "Statement_End_Block", "anonymous block terminator statement awareness");
      Require_Marker (Parser_Body, "Statement_Accept_Alternative", "same-line selective accept alternative statement awareness");
      Require_Marker (Parser_Body, "Statement_Accept_Body", "accept-body statement awareness");
      Require_Marker (Parser_Body, "Mark_Accept_Details", "accept profile/family statement awareness");
      Require_Marker (Parser_Body, "Statement_Accept_With_Profile", "accept-profile statement awareness");
      Require_Marker (Parser_Body, "Statement_Accept_Entry_Family_Index", "accept entry-family statement awareness");
      Require_Marker (Parser_Body, "Statement_Delay_Until", "delay-until statement awareness");
      Require_Marker (Parser_Body, "Statement_Delay_Relative", "relative delay statement awareness");
      Require_Marker (Parser_Body, "Mark_Delay_Details", "centralized delay statement awareness");
      Require_Marker (Parser_Body, "Statement_Delay_Alternative", "selective-accept delay alternative statement awareness");
      Require_Marker (Parser_Body, "Statement_Delay_Alternative_Until", "delay-until alternative statement awareness");
      Require_Marker (Parser_Body, "Statement_Delay_Alternative_Relative", "relative delay alternative statement awareness");
      Require_Marker (Parser_Body, "Statement_Exit_When", "conditional exit statement awareness");
      Require_Marker (Parser_Body, "Mark_Exit_Details", "named-loop exit statement awareness");
      Require_Marker (Parser_Body, "Statement_Exit_Named_Loop", "named-loop exit statement awareness");
      Require_Marker (Parser_Body, "Mark_Raise_Details", "raise form statement awareness");
      Require_Marker (Parser_Body, "Statement_Raise_Reraise", "reraise statement awareness");
      Require_Marker (Parser_Body, "Statement_Raise_Exception_Name", "raise exception-name statement awareness");
      Require_Marker (Parser_Body, "Statement_Raise_With_Message", "raise-with-message statement awareness");
      Require_Marker (Parser_Body, "Statement_Requeue_With_Abort", "requeue-with-abort statement awareness");
      Require_Marker (Parser_Body, "Mark_Requeue_Target_Details", "requeue target-shape statement awareness");
      Require_Marker (Parser_Body, "Statement_Requeue_Selected_Target", "selected requeue-target statement awareness");
      Require_Marker (Parser_Body, "Statement_Requeue_With_Arguments", "requeue argument target statement awareness");
      Require_Marker (Parser_Body, "Looks_Like_Code_Statement", "Ada code-statement recognition");
      Require_Marker (Parser_Body, "Statement_Call_With_Arguments", "procedure-call argument awareness");
      Require_Marker (Parser_Body, "Statement_Call_With_Named_Association", "procedure-call named-association awareness");
      Require_Marker (Parser_Body, "Statement_Call_Selected_Name", "selected-name call statement awareness");
      Require_Marker (Parser_Body, "Statement_Call_Access_Dereference", "access-dereference call statement awareness");
      Require_Marker (Parser_Body, "Statement_Call_Attribute_Name", "attribute-name call statement awareness");
      Require_Marker (Parser_Body, "Mark_Pragma_Details", "pragma statement awareness");
      Require_Marker (Parser_Body, "Statement_Call_Entry_Family_Index", "entry-family call statement awareness");
      Require_Marker (Parser_Body, "Call_Has_Access_Dereference", "access-dereference call detection");
      Require_Marker (Parser_Body, "Call_Has_Entry_Family_Index", "entry-family call detection");
      Require_Marker (Parser_Body, "Statement_Null_Alternative", "null alternative statement awareness");
      Require_Marker (Parser_Body, "Mark_Alternative_Action", "alternative action statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Raise", "alternative raise-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Return", "alternative return-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Return_With_Expression", "return-expression statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Return_With_Expression", "alternative return-expression statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Assignment", "alternative assignment-action statement awareness");
      Require_Marker (Parser_Body, "Mark_Assignment_Target_Details", "assignment target-shape statement awareness");
      Require_Marker (Parser_Body, "Statement_Assignment_Selected_Target", "selected assignment-target statement awareness");
      Require_Marker (Parser_Body, "Statement_Assignment_Access_Dereference", "access-dereference assignment-target statement awareness");
      Require_Marker (Parser_Body, "Statement_Assignment_Indexed_Target", "indexed assignment-target statement awareness");
      Require_Marker (Parser_Body, "Statement_Assignment_Slice_Target", "slice assignment-target statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Call", "alternative call-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Exit", "alternative exit-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Goto", "alternative goto-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Delay", "alternative delay-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Requeue", "alternative requeue-action statement awareness");
      Require_Marker (Parser_Body, "Statement_Alternative_Abort", "alternative abort-action statement awareness");
      Require_Marker (Parser_Body, "Mark_Abort_Target_Details", "abort target-shape statement awareness");
      Require_Marker (Parser_Body, "Statement_Abort_Selected_Target", "selected abort-target statement awareness");
      Require_Marker (Parser_Body, "Statement_Abort_Multiple_Targets", "multiple abort-target statement awareness");
      Require_Marker (Parser_Body, "Call_Has_Named_Association", "procedure-call named-association recognition");
      Require_Marker (Parser_Body, "Call_Has_Selected_Name", "selected-name call recognition");

      Require_Marker (Parser_Body, "Statement_Code", "Ada code-statement awareness");
      Require_Marker (Parser_Body, "Mark_Pragma_Target", "pragma target metadata binding");
      Require_Marker (Parser_Body, "Mark_Context_Clause_Awareness", "context/use clause awareness binding");
      Require_Marker (Parser_Body, "Has_Null_Exclusion", "null-exclusion metadata detection");
      Require_Marker (Parser_Body, "Has_Aliased_Metadata", "aliased declaration metadata detection");
      Require_Marker (Parser_Body, "Mark_Type_Qualifier_Metadata", "type qualifier metadata detection");
      Require_Marker (Parser_Body, "Has_Task_Interface_Metadata", "task interface metadata detection");
      Require_Marker (Parser_Body, "Has_Protected_Interface_Metadata", "protected interface metadata detection");
      Require_Marker (Parser_Body, "Has_Task_Type_Metadata", "task type metadata detection");
      Require_Marker (Parser_Body, "Has_Protected_Type_Metadata", "protected type metadata detection");
      Require_Marker (Parser_Body, "Mark_Declaration_Form_Metadata", "access/array/derived declaration-form metadata detection");
      Require_Marker (Parser_Body, "Has_Access_Protected_Metadata", "access protected subprogram metadata detection");
      Require_Marker (Parser_Body, "Has_Token_Pair", "access mode token-pair detection");
      Require_Marker (Parser_Body, "Has_Class_Wide_Metadata", "class-wide subtype-mark detection");
      Require_Marker (Parser_Body, "Mark_Symbol_Variant_Record_Metadata", "variant record metadata binding");
      Require_Marker (Parser_Body, "Has_Default_Expression_Metadata", "default expression metadata detection");
      Require_Marker (Parser_Body, "Has_Entry_Family_Metadata", "entry-family metadata detection");
      Require_Marker (Parser_Body, "Has_Incomplete_Type_Metadata", "incomplete type metadata detection");
      Require_Marker (Parser_Body, "Has_Profile_Mode_Metadata", "profile mode metadata detection");
      Require_Marker (Parser_Body, "Has_Entry_Barrier_Metadata", "entry barrier metadata detection");
      Require_Marker (Parser_Body, "Has_Box_Metadata", "box metadata detection");
      Require_Marker (Parser_Body, "Has_Named_Number_Metadata", "named-number metadata detection");
      Require_Marker (Parser_Body, "Has_Deferred_Constant_Metadata", "deferred-constant metadata detection");
      Require_Marker (Parser_Body, "Has_Null_Subprogram_Metadata", "null-subprogram metadata detection");
      Require_Marker (Parser_Body, "Has_Expression_Function_Metadata", "expression-function metadata detection");
      Require_Marker (Parser_Body, "Has_Null_Record_Metadata", "null-record metadata detection");
      Require_Marker (Parser_Body, "Has_Discriminant_Part_Metadata", "discriminant-part metadata detection");
      Require_Marker (Parser_Body, "Has_Body_Stub_Metadata", "body-stub metadata detection");
      Require_Marker (Parser_Body, "Has_Constraint_Metadata", "constraint metadata detection");
      Require_Marker (Parser_Body, "Has_Child_Unit_Metadata", "child unit metadata detection");
      Require_Marker (Parser_Body, "Has_Generic_Actual_Part_Metadata", "generic actual part metadata detection");
      Require_Marker (Parser_Body, "Is_Abstract", "abstract declaration retention");
      Require_Marker (Parser_Body, "Is_Overriding", "overriding indicator retention");
      Require_Marker (Parser_Body, "Is_Not_Overriding", "not-overriding indicator retention");
      Require_Marker (Parser_Body, "Pending_Enumeration", "multiline enumeration parsing");
      Require_Marker (Parser_Body, "Pending_Profile", "multiline profile parsing");
      Require_Marker (Parser_Body, "Pending_Body_Owner", "split body owner parsing");
      Require_Marker (Parser_Body, "Pending_Type_Header_Owner", "split type header parsing");
      Require_Marker (Parser_Body, "Pending_Record_After_Is_Owner", "split record scope opening");
      Require_Marker (Parser_Body, "Column_Base", "source-column range preservation");
      Require_Marker (Parser_Body, "Mark_Statement_Awareness", "statement grammar awareness");
      Require_Marker (Parser_Body, "Statement_If", "if statement awareness");
      Require_Marker (Parser_Body, "Statement_For_In_Loop", "for-in loop statement awareness");
      Require_Marker (Parser_Body, "Statement_For_Of_Loop", "for-of loop statement awareness");
      Require_Marker (Parser_Body, "Statement_For_Reverse_Loop", "reverse for-loop statement awareness");
      Require_Marker (Parser_Body, "Statement_While_Loop", "loop statement awareness");
      Require_Marker (Parser_Body, "Statement_Select", "tasking select statement awareness");
      Require_Marker (Parser_Body, "Statement_End_Loop", "structured loop terminator awareness");
      Require_Marker (Parser_Body, "Statement_End_Named_Loop", "named loop terminator awareness");
      Require_Marker (Token_Cursor_Spec, "Production_Subtype_Mark", "subtype-indication explicit subtype-mark production");
      Require_Marker (Token_Cursor_Spec, "Production_Subtype_Null_Exclusion", "subtype-indication null-exclusion production");
      Require_Marker (Token_Cursor_Spec, "Production_Subtype_Range_Constraint", "subtype-indication range constraint production");
      Require_Marker (Token_Cursor_Spec, "Production_Subtype_Digits_Constraint", "subtype-indication digits constraint production");
      Require_Marker (Token_Cursor_Spec, "Production_Subtype_Delta_Constraint", "subtype-indication delta constraint production");
      Require_Marker (Token_Cursor_Spec, "Production_Subtype_Index_Constraint", "subtype-indication index constraint production");
      Require_Marker (Token_Cursor_Spec, "Production_Subtype_Discriminant_Constraint", "subtype-indication discriminant constraint production");
      Require_Marker (Token_Cursor_Body, "subtype index constraint", "subtype-indication index parser path");
      Require_Marker (Token_Cursor_Body, "subtype discriminant constraint", "subtype-indication discriminant parser path");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Subtype_Indication_Depth_Grammar_Completeness", "subtype-indication depth regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Number_Defining_Name", "number declaration defining-name production");
      Require_Marker (Token_Cursor_Spec, "Production_Number_Constant_Keyword", "number declaration constant-keyword production");
      Require_Marker (Token_Cursor_Spec, "Production_Number_Declaration_Recovery_Boundary", "number declaration recovery-boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Number_Declaration_Terminator", "number declaration terminator production");
      Require_Marker (Token_Cursor_Spec, "Production_Number_Declaration_Missing_Terminator_Recovery_Boundary", "number declaration missing-terminator recovery production");
      Require_Marker (Token_Cursor_Spec, "Production_Enumeration_Representation_List_Open_Delimiter", "enumeration representation list open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Enumeration_Representation_List_Close_Delimiter", "enumeration representation list close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Enumeration_Representation_Association_Separator", "enumeration representation association separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Enumeration_Representation_Missing_Close_Recovery_Boundary", "enumeration representation missing-close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Enumeration_Representation_Delimiters_Pass818", "enumeration representation delimiter regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Record_Representation_List_Open_Delimiter", "record representation list open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Record_Representation_List_Close_Delimiter", "record representation list close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Record_Representation_Component_Separator", "record representation component separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Record_Representation_Missing_Close_Recovery_Boundary", "record representation missing-close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Record_Representation_Delimiters_Pass819", "record representation delimiter regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Part_Open_Delimiter", "generic actual part open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Part_Close_Delimiter", "generic actual part close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Association_Separator", "generic actual association separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary", "generic actual part missing-close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters_Pass822", "generic instantiation actual delimiter regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Protected_Body_Operation_End_Name", "protected operation body end-name production");
      Require_Marker (Token_Cursor_Spec, "Production_Protected_Body_Operation_End_Terminator", "protected operation body end terminator production");
      Require_Marker (Token_Cursor_Spec, "Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary", "protected operation body missing end-terminator recovery production");
      Require_Marker (Token_Cursor_Body, "Is_Nested_Statement_End_Follower", "protected operation body nested statement end guard");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail_Pass823", "protected operation body end detail regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Choice_Missing_Choice_Recovery_Boundary", "exception handler missing choice recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice_Pass824", "exception handler missing choice regression coverage");
      Require_Marker (Token_Cursor_Body, "exception choice separator missing following choice", "exception handler missing choice parser path");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Visible_Declarative_Item_Recovery_Boundary", "package visible declarative item recovery production");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Private_Declarative_Item_Recovery_Boundary", "package private declarative item recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Pass825", "package declarative item recovery regression coverage");
      Require_Marker (Token_Cursor_Body, "package visible declarative item recovery boundary", "package visible declarative item recovery parser path");
      Require_Marker (Token_Cursor_Body, "package private declarative item recovery boundary", "package private declarative item recovery parser path");
      Require_Marker (Token_Cursor_Spec, "Production_Parameter_Profile_Open_Delimiter", "parameter profile open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Parameter_Profile_Close_Delimiter", "parameter profile close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Parameter_Profile_Separator", "parameter profile separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Parameter_Profile_Missing_Close_Recovery_Boundary", "parameter profile missing close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters_Pass826", "parameter profile delimiter regression coverage");
      Require_Marker (Token_Cursor_Body, "parameter profile open delimiter", "parameter profile open delimiter parser path");
      Require_Marker (Token_Cursor_Body, "parameter profile missing close recovery boundary", "parameter profile missing-close parser path");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Part_Open_Delimiter", "discriminant part open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Part_Close_Delimiter", "discriminant part close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Specification_Separator", "discriminant specification separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Part_Missing_Close_Recovery_Boundary", "discriminant part missing close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters_Pass827", "discriminant part delimiter regression coverage");
      Require_Marker (Token_Cursor_Body, "discriminant part open delimiter", "discriminant part open delimiter parser path");
      Require_Marker (Token_Cursor_Body, "discriminant part missing close recovery boundary", "discriminant part missing-close parser path");
      Require_Marker (Token_Cursor_Spec, "Production_Index_Constraint_Open_Delimiter", "index constraint open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Index_Constraint_Close_Delimiter", "index constraint close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Index_Constraint_Item_Separator", "index constraint item separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Index_Constraint_Missing_Close_Recovery_Boundary", "index constraint missing close recovery production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Constraint_Open_Delimiter", "discriminant constraint open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Constraint_Close_Delimiter", "discriminant constraint close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Association_Separator", "discriminant association separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Constraint_Missing_Close_Recovery_Boundary", "discriminant constraint missing close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Constraint_Delimiters_Pass828", "constraint delimiter regression coverage");
      Require_Marker (Token_Cursor_Body, "index constraint open delimiter", "index constraint open delimiter parser path");
      Require_Marker (Token_Cursor_Body, "index constraint missing close recovery boundary", "index constraint missing-close parser path");
      Require_Marker (Token_Cursor_Body, "discriminant constraint open delimiter", "discriminant constraint open delimiter parser path");
      Require_Marker (Token_Cursor_Body, "discriminant constraint missing close recovery boundary", "discriminant constraint missing-close parser path");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Open_Delimiter", "aggregate open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Close_Delimiter", "aggregate close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Component_Separator", "aggregate component separator production");
      Require_Marker (Token_Cursor_Spec, "Production_Aggregate_Missing_Close_Recovery_Boundary", "aggregate missing close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Aggregate_Delimiters_Pass829", "aggregate delimiter regression coverage");
      Require_Marker (Token_Cursor_Body, "aggregate component separator", "aggregate component separator parser path");
      Require_Marker (Token_Cursor_Body, "missing aggregate or parenthesized expression close delimiter", "aggregate missing-close parser path");
      Require_Marker (Token_Cursor_Spec, "Production_Qualified_Expression_Operand_Open_Delimiter", "qualified-expression operand open delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Qualified_Expression_Operand_Close_Delimiter", "qualified-expression operand close delimiter production");
      Require_Marker (Token_Cursor_Spec, "Production_Qualified_Expression_Operand_Missing_Close_Recovery_Boundary", "qualified-expression operand missing close recovery production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters_Pass830", "qualified-expression operand delimiter regression coverage");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters_Pass831", "parenthesized-expression delimiter regression coverage");
      Require_Marker (Token_Cursor_Body, "qualified-expression operand open delimiter", "qualified-expression operand open delimiter parser path");
      Require_Marker (Token_Cursor_Body, "missing qualified-expression operand close delimiter", "qualified-expression operand missing-close parser path");
      Require_Marker (Token_Cursor_Body, "number defining name separator", "number declaration defining-name separator parser path");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Number_Declaration_Depth_Grammar_Completeness", "number declaration depth regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Object_Defining_Name", "object declaration defining-name production");
      Require_Marker (Token_Cursor_Spec, "Production_Object_Access_Definition", "object declaration access-definition production");
      Require_Marker (Token_Cursor_Spec, "Production_Object_Declaration_Recovery_Boundary", "object declaration recovery-boundary production");
      Require_Marker (Token_Cursor_Body, "object access definition", "object declaration access-definition parser path");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Object_Declaration_Depth_Grammar_Completeness", "object declaration depth regression coverage");
   end Check_Parser_And_Model_Features;

   procedure Check_Resolver_And_Index_Features is
   begin
      Require_Marker (Resolver_Spec, "Resolve_In_Scope", "scope-aware resolver API");
      Require_Marker (Resolver_Body, "actual lexical parent chain", "lexical parent-chain resolver");
      Require_Marker (Resolver_Body, "resolve the prefix in the current lexical chain", "selected-name resolver");
      Require_Marker (Resolver_Body, "Generic_Target_Symbol", "generic instance target resolver");
      Require_Marker (Resolver_Body, "Substitute_Generic_Actual_Type", "generic actual substitution");
      Require_Marker (Resolver_Body, "Use_Clause_Count", "resolver uses individual use-clause projection");
      Require_Marker (Resolver_Body, "Selected : constant Boolean", "selected-name resolver guards");
      Require_Marker (Index_Spec, "Contains_Current", "current-stamped index lookup");
      Require_Marker (Index_Spec, "Contains_Key", "exact target-key revalidation");
      Require_Marker (Index_Spec, "Contains_Open_Buffer_Key", "open-buffer target-key revalidation");
      Require_Marker (Index_Spec, "Resolve_Current", "current-stamped index lookup");
      Require_Marker (Index_Spec, "Resolve_Unique_Navigation_Target", "unique navigation target API");
      Require_Marker (Index_Spec, "Indexed_Unit_Role", "cross-file Ada unit table roles");
      Require_Marker (Index_Spec, "Resolve_Unit", "cross-file Ada unit lookup API");
      Require_Marker (Index_Spec, "Resolve_Related_Unit_Target", "unit spec/body relationship API");
      Require_Marker (Index_Spec, "Resolve_Separate_Parent_Target", "separate-parent unit relationship API");
      Require_Marker (Index_Spec, "Resolve_Parent_Unit_Target", "child-unit parent relationship API");
      Require_Marker (Index_Spec, "Resolve_Child_Units", "direct child-unit listing API");
      Require_Marker (Index_Spec, "Resolve_Unit_Family", "validated unit-family target listing API");
      Require_Marker (Index_Spec, "Index_Resolution_Result", "bounded index resolution result");
      Require_Marker (Index_Body, "Key_Is_Current", "stale index rejection");
      Require_Marker (Index_Body, "Pass 200: indexed navigation targets carry", "target-key revalidation implementation");
      Require_Marker (Index_Body, "Qualified_Name", "qualified project-index lookup");
      Require_Marker (Index_Body, "Qualified project-index lookup must not devolve to leaf-only", "qualified lookup guard");
      Require_Marker (Index_Body, "Rebuild_Units", "cross-file Ada unit table rebuild");
      Require_Marker (Index_Body, "Unit_Name_For", "normalized Ada unit identity projection");
      Require_Marker (Index_Body, "Role_Matches", "unit role relationship filtering");
      Require_Marker (Index_Body, "Overflow", "overflow-aware index resolution");
   end Check_Resolver_And_Index_Features;

   procedure Check_Test_Coverage is
   begin
      Require_Syntax_Test ("Test_Language_Model_Scopes_Shadowing_And_Parents", "scoped semantic binding");
      Require_Syntax_Test ("Test_Scope_Aware_Semantic_Classification_Uses_Resolver", "resolver-backed semantic classification");
      Require_Syntax_Test ("Test_Overlong_Scoped_Semantic_Lookup_Degrades", "bounded semantic degradation");
      Require_Syntax_Test ("Test_Project_Index_Resolves_Cross_File_Symbols", "project index");
      Require_Syntax_Test ("Test_Project_Index_Qualified_Lookup_Does_Not_Leaf_Match", "qualified project index");
      Require_Syntax_Test ("Test_Project_Index_Invalidates_Buffer_And_Path", "project index invalidation");
      Require_Syntax_Test ("Test_Project_Index_Current_Stamp_Rejection", "stale index rejection");
      Require_Syntax_Test ("Test_Project_Index_Unique_Navigation_Target_Rejects_Ambiguity", "unique navigation");
      Require_Syntax_Test ("Test_Project_Index_Unique_Navigation_Target_Uses_Profile", "profile-aware navigation");
      Require_Syntax_Test ("Test_Project_Index_Unique_Navigation_Target_Rejects_Overflow", "overflow-safe navigation");
      Require_Syntax_Test ("Test_Project_Index_Target_Key_Revalidation", "target-key revalidation");
      Require_Syntax_Test ("Test_Project_Index_Cross_File_Unit_Relationship_Table", "cross-file Ada unit relationships");
      Require_Syntax_Test ("Test_Project_Index_Child_Unit_Parent_Relationship_Target", "child-unit parent relationships");
      Require_Syntax_Test ("Test_Project_Index_Parent_Lists_Direct_Child_Units", "direct child-unit listing");
      Require_Syntax_Test ("Test_Project_Index_Unit_Family_Lists_Validated_Targets", "validated unit-family target listing");
      Require_Syntax_Test ("Test_Project_Index_Unit_Table_Excludes_Nested_Declarations", "library-unit-only unit table rows");
      Require_Marker (Syntax_Tests, "normalize path spellings during revalidation", "normalized target-key revalidation test coverage");
      Require_Syntax_Test ("Test_Language_Model_Representation_Clauses_Are_Metadata", "representation metadata");
      Require_Marker (Syntax_Tests, "aspect specification should be retained as declaration metadata", "aspect metadata test coverage");
      Require_Syntax_Test ("Test_Language_Model_Pragma_Metadata_Does_Not_Pollute_Symbols", "pragma metadata");
      Require_Syntax_Test ("Test_Language_Model_Pragma_Placement_And_Target_Metadata", "pragma placement target and argument metadata");
      Require_Syntax_Test ("Test_Language_Model_Representation_Operational_Projection_Metadata", "consistent representation and operational clause projection metadata");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Package_Declarative_Item_Hostile_Recovery", "hostile package declarative item recovery");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Declarative_Recovery_Boundary", "package declarative recovery boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Unexpected_Begin_Boundary", "unexpected package begin recovery boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Body_Unexpected_Private_Boundary", "unexpected package-body private recovery boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Duplicate_Private_Boundary", "duplicate package private recovery boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Private_Begin_Recovery_Boundary", "package private begin recovery boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Package_Body_Private_Declarative_Recovery_Boundary", "package-body private declarative recovery boundary production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth_Pass937", "package declarative section recovery depth");
      Require_Marker (Token_Cursor_Spec, "Production_If_Expression_Condition_Reserved_Boundary", "if-expression condition reserved boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Case_Expression_Missing_Selector_Recovery_Boundary", "case-expression missing selector recovery boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Case_Expression_Missing_Is_Recovery_Boundary", "case-expression missing-is recovery boundary production");
      Require_Marker (Token_Cursor_Spec, "Production_Parallel_Reduction_Argument_Recovery_Boundary", "parallel-reduction argument recovery boundary production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth_Pass939", "expression recovery refinement depth");
      Require_Marker (Syntax_Tests, "Production_Body_Stub_Aspect_Specification", "deep aspect placement regression coverage");
      Require_Marker (Syntax_Tests, "Production_Protected_Operation_Aspect_Attachment", "protected operation aspect placement regression coverage");
      Require_Syntax_Test ("Test_Language_Model_Generated_And_Conditional_Source_Awareness", "generated/conditional awareness");
      Require_Syntax_Test ("Test_Language_Model_Context_Clauses_Are_Metadata", "context/use clause metadata");
      Require_Syntax_Test ("Test_Language_Model_Use_Clauses_Project_Individual_Metadata", "individual use-clause metadata projection");
      Require_Syntax_Test ("Test_Language_Model_Null_Exclusions_Are_Metadata", "null-exclusion metadata");
      Require_Syntax_Test ("Test_Language_Model_Aliased_Metadata_Does_Not_Pollute_Symbols", "aliased declaration metadata");
      Require_Syntax_Test ("Test_Language_Model_Type_Qualifier_Metadata", "type qualifier metadata");
      Require_Syntax_Test ("Test_Language_Model_Synchronized_Metadata", "synchronized interface metadata");
      Require_Syntax_Test ("Test_Language_Model_Task_And_Protected_Interface_Metadata", "task/protected interface metadata");
      Require_Syntax_Test ("Test_Language_Model_Access_And_Array_Metadata", "access and array declaration-form metadata");
      Require_Syntax_Test ("Test_Language_Model_Derived_Type_Metadata", "derived type declaration metadata");
      Require_Syntax_Test ("Test_Language_Model_Scalar_Type_Metadata", "scalar numeric type metadata");
      Require_Syntax_Test ("Test_Language_Model_Variant_Record_Metadata", "variant record metadata");
      Require_Syntax_Test ("Test_Language_Model_Default_Expression_Metadata", "default expression metadata");
      Require_Syntax_Test ("Test_Language_Model_Entry_Family_Metadata", "entry-family metadata");
      Require_Syntax_Test ("Test_Language_Model_Entry_Barrier_Metadata", "entry barrier metadata");
      Require_Syntax_Test ("Test_Language_Model_Access_Mode_Metadata", "access mode metadata");
      Require_Syntax_Test ("Test_Language_Model_Class_Wide_Metadata", "class-wide metadata");
      Require_Syntax_Test ("Test_Language_Model_Box_Metadata", "box metadata");
      Require_Syntax_Test ("Test_Language_Model_Named_Number_Metadata", "named-number metadata");
      Require_Syntax_Test ("Test_Language_Model_Deferred_Constant_Metadata", "deferred-constant metadata");
      Require_Syntax_Test ("Test_Language_Model_Null_Subprogram_And_Expression_Function_Metadata", "null subprogram/expression function metadata");
      Require_Syntax_Test ("Test_Language_Model_Null_Record_Metadata", "null record metadata");
      Require_Syntax_Test ("Test_Language_Model_Discriminant_Part_Metadata", "discriminant part metadata");
      Require_Syntax_Test ("Test_Language_Model_Body_Stub_Metadata", "body-stub metadata");
      Require_Syntax_Test ("Test_Language_Model_Overriding_Indicator_Metadata", "overriding indicator metadata");
      Require_Syntax_Test ("Test_Language_Model_Constraint_Metadata", "constraint metadata");
      Require_Syntax_Test ("Test_Language_Model_Child_Unit_Metadata", "child unit metadata");
      Require_Syntax_Test ("Test_Language_Model_Access_Protected_Metadata", "access protected metadata");
      Require_Syntax_Test ("Test_Language_Model_Incomplete_Type_Metadata", "incomplete type metadata");
      Require_Syntax_Test ("Test_Language_Model_Generic_Actual_Part_Metadata", "generic actual part metadata");
      Require_Syntax_Test ("Test_Resolver_Generic_Instance_Expansion_Uses_Actuals", "generic instance semantic expansion");
      Require_Syntax_Test ("Test_Language_Model_Split_Aspect_Clause_Metadata", "split aspect metadata");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Projection_Feeds_Symbols", "syntax-tree projection into language-model symbols");
      Require_Marker (Syntax_Tests, "record representation syntax-tree clauses should mark the target symbol", "syntax-tree representation metadata projection coverage");
      Require_Syntax_Test ("Test_Language_Model_Statement_Awareness", "statement awareness metadata");
      Require_Marker (Syntax_Tests, "For_Form_Source", "for-loop iteration-scheme statement coverage");
      Require_Marker (Syntax_Tests, "Statement_For_Of_Loop", "for-of loop statement coverage");
      Require_Marker (Syntax_Tests, "Statement_For_Reverse_Loop", "reverse for-loop statement coverage");
      Require_Marker (Syntax_Tests, "Statement_End_Named_Loop", "named end-loop statement coverage");
      Require_Marker (Syntax_Tests, "Statement_End_Block", "anonymous block terminator statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Exit_Named_Loop", "named-loop exit statement coverage");
      Require_Marker (Syntax_Tests, "Delay_Alternative_Source", "delay alternative statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Delay_Alternative_Until", "delay-until alternative statement coverage");
      Require_Marker (Syntax_Tests, "Return_Expression_Source", "return-expression statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Alternative_Return_With_Expression", "alternative return-expression statement coverage");
      Require_Marker (Syntax_Tests, "Raise_Form_Source", "raise form statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Raise_Reraise", "reraise statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Raise_Exception_Name", "raise exception-name statement coverage");
      Require_Marker (Syntax_Tests, "Accept_Alternative_Source", "same-line selective accept alternative coverage");
      Require_Marker (Syntax_Tests, "Statement_Accept_Alternative", "same-line selective accept alternative statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Then_Abort_Action", "same-line then-abort action statement coverage");
      Require_Marker (Syntax_Tests, "Compact_Loop_Action_Source", "same-line loop-body action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Loop_Action", "same-line loop-body action statement coverage");
      Require_Marker (Syntax_Tests, "Compact_Case_Action_Source", "same-line case alternative action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Case_Alternative_Action", "same-line case alternative action statement coverage");
      Require_Marker (Syntax_Tests, "Compact_Exception_Action_Source", "same-line exception handler action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Exception_Handler_Action", "same-line exception handler action statement coverage");
      Require_Marker (Syntax_Tests, "Compact_Begin_Action_Source", "same-line begin action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Begin_Action", "same-line begin action statement coverage");
      Require_Marker (Syntax_Tests, "Compact_Then_Action_Source", "same-line if-then action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Then_Action", "same-line if-then action statement coverage");
      Require_Marker (Syntax_Tests, "Goto_Target_Source", "goto label-target statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Goto_Label_Target", "goto label-target statement coverage");
      Require_Marker (Syntax_Tests, "Compact_Elsif_Action_Source", "same-line if-elsif action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Elsif_Action", "same-line if-elsif action statement coverage");
      Require_Marker (Syntax_Tests, "Compact_Else_Action_Source", "same-line if-else action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Else_Action", "same-line if-else action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Accept_With_Profile", "accept-profile statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Accept_Entry_Family_Index", "accept entry-family statement coverage");
      Require_Marker (Syntax_Tests, "Conditional_Entry_Call_Source", "conditional entry-call select statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Entry_Call", "conditional entry-call select statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Action", "conditional entry-call select else-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Null", "conditional entry-call select else-null statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Return", "conditional entry-call select else-return statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Raise", "conditional entry-call select else-raise statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Assignment", "conditional entry-call select else-assignment statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Call", "conditional entry-call select else-call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Code", "conditional entry-call select else-code statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Exit", "conditional entry-call select else-exit statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Goto", "conditional entry-call select else-goto statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Delay", "conditional entry-call select else-delay statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Delay_Until", "conditional entry-call select else-delay-until statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Delay_Relative", "conditional entry-call select else-relative-delay statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Requeue", "conditional entry-call select else-requeue statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Requeue_With_Abort", "conditional entry-call select else-requeue-with-abort statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Abort", "conditional entry-call select else-abort statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Pragma", "conditional entry-call select else-pragma statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Else_Pragma_With_Arguments", "conditional entry-call select else-pragma-arguments statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback", "timed entry-call select delay-fallback statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Action", "timed entry-call select delay-fallback action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Null", "timed entry-call select delay-fallback null-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Call", "timed entry-call select delay-fallback call-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Call_With_Arguments", "timed entry-call select delay-fallback argument-call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Call_With_Named_Association", "timed entry-call select delay-fallback named-association call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Call_Selected_Name", "timed entry-call select delay-fallback selected-call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Call_Access_Dereference", "timed entry-call select delay-fallback access-call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Call_Entry_Family_Index", "timed entry-call select delay-fallback entry-family call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Assignment", "timed entry-call select delay-fallback assignment-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Return", "timed entry-call select delay-fallback return-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Raise", "timed entry-call select delay-fallback raise-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Code", "timed entry-call select delay-fallback code-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Exit", "timed entry-call select delay-fallback exit-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Goto", "timed entry-call select delay-fallback goto-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Delay", "timed entry-call select delay-fallback delay-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Requeue", "timed entry-call select delay-fallback requeue-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Abort", "timed entry-call select delay-fallback abort-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Pragma", "timed entry-call select delay-fallback pragma-action statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Delay_Fallback_Pragma_With_Arguments", "timed entry-call select delay-fallback pragma-argument statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Then_Abort_Fallback", "asynchronous select then-abort fallback statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Terminate_Fallback", "selective accept terminate fallback statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Select_Abortable_Call", "asynchronous select abortable call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Requeue_Selected_Target", "selected requeue-target statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Requeue_With_Arguments", "requeue argument target statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Call_Access_Dereference", "access-dereference call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Call_Attribute_Name", "attribute-name call statement coverage");
      Require_Marker (Syntax_Tests, "Pragma_Statement_Source", "pragma statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Pragma", "pragma statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Pragma_With_Arguments", "pragma argument statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Alternative_Pragma", "alternative pragma-action statement coverage");
      Require_Marker (Syntax_Tests, "Entry_Family_Call_Source", "entry-family call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Call_Entry_Family_Index", "entry-family call statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Assignment_Access_Dereference", "access-dereference assignment statement coverage");
      Require_Marker (Syntax_Tests, "requeue target-shape metadata coexists", "requeue target-shape statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Abort_Selected_Target", "selected abort-target statement coverage");
      Require_Marker (Syntax_Tests, "Statement_Abort_Multiple_Targets", "multiple abort-target statement coverage");
      Require_Marker (Syntax_Tests, "multiple leading statement labels are counted individually", "stacked labelled-statement test coverage");
      Require_Marker (Syntax_Tests, "stacked labels are stripped before classifying", "stacked labelled-statement test coverage");
      Require_Marker (Syntax_Tests, "compact same-line statement sequences", "compact same-line statement test coverage");
      Require_Marker (Syntax_Tests, "inline null actions in compact same-line statement sequences", "compact same-line statement test coverage");
      Require_Marker (Syntax_Tests, "inline end-select terminators in compact same-line statement sequences", "compact same-line statement test coverage");
      Require_Marker (Syntax_Tests, "null alternatives in case/exception alternatives", "null alternative statement test coverage");
      Require_Marker (Syntax_Tests, "assignment actions after executable alternatives", "alternative action statement test coverage");
      Require_Marker (Syntax_Tests, "call actions after executable alternatives", "alternative action statement test coverage");
      Require_Marker (Syntax_Tests, "return actions after executable alternatives", "alternative action statement test coverage");
      Require_Marker (Syntax_Tests, "raise actions after executable alternatives", "alternative action statement test coverage");
      Require_Marker (Syntax_Tests, "record variant null alternatives", "variant null-alternative non-pollution test coverage");
      Require_Syntax_Test ("Test_Language_Model_Separate_Body_Kind_And_Semantics", "separate bodies");
      Require_Syntax_Test ("Test_Language_Model_Enumeration_Literals_Parent_Type", "enumeration literals");
      Require_Syntax_Test ("Test_Language_Model_Multiline_Enumeration_Literals_Parent_Type", "multiline enumeration literals");
      Require_Syntax_Test ("Test_Language_Model_Subprogram_Profile_Parameters", "profile parameters");
      Require_Syntax_Test ("Test_Language_Model_Multiline_Profile_Parameters", "multiline profile parameters");
      Require_Syntax_Test ("Test_Language_Model_Split_Type_Header_Record", "split type headers");
      Require_Syntax_Test ("Test_Language_Model_Split_Profile_Body_Opens_Callable_Scope", "split callable bodies");
      Require_Syntax_Test ("Test_Language_Model_Private_Child_Package_Name", "private child packages");
      Require_Syntax_Test ("Test_Language_Model_Generic_Formal_Object_And_Profiles", "generic formal objects");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Record_Representation_Component_Clauses_Are_Structured", "record representation component clause syntax-tree structure");
      Require_Marker (Test_Body, "Node_Abstract_Subprogram_Declaration", "abstract subprogram declaration regression coverage");
      Require_Marker (Test_Body, "Node_Null_Procedure_Declaration", "null procedure declaration regression coverage");
      Require_Marker (Test_Body, "Node_Expression_Function_Declaration", "expression function declaration regression coverage");
      Require_Marker (Test_Body, "Node_Declaration_Profile", "subprogram profile declaration-detail regression coverage");
      Require_Marker (Test_Body, "Node_Declaration_Result", "function result declaration-detail regression coverage");
      Require_Marker (Test_Body, "Node_Enumeration_Literal_Declaration", "enumeration literal declaration regression coverage");
      Require_Marker (Test_Body, "Node_Variant_Part", "variant part declaration regression coverage");
      Require_Marker (Test_Body, "Node_Variant", "variant declaration regression coverage");
      Require_Marker (Test_Body, "Node_Entry_Body", "entry body declaration regression coverage");
      Require_Marker (Test_Body, "Node_Entry_Body_Stub", "entry body stub regression coverage");
      Require_Marker (Test_Body, "Node_Task_Type_Declaration", "task type declaration regression coverage");
      Require_Marker (Test_Body, "Node_Single_Task_Declaration", "single task declaration regression coverage");
      Require_Marker (Test_Body, "Node_Protected_Type_Declaration", "protected type declaration regression coverage");
      Require_Marker (Test_Body, "Node_Single_Protected_Declaration", "single protected declaration regression coverage");
      Require_Marker (Test_Body, "Node_Declaration_Target", "renaming target declaration-detail regression coverage");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_All_Ada_Declaration_Forms_Are_Structured", "all Ada declaration families syntax-tree structure");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Constants_And_Assignment_Are_Separated", "constant declaration and assignment separation syntax-tree structure");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Grammar_Aware_Recovery", "grammar-aware syntax-tree recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Named_End_Target_Recovery", "named end-target grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Implicit_Statement_Part_Recovery", "implicit statement-part grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Generic_Formal_Part_Recovery", "generic formal-part grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Malformed_Header_Recovery", "malformed Ada header expected-token grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Malformed_Alternative_Recovery", "malformed Ada alternative expected-arrow grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Malformed_Declaration_Recovery", "malformed Ada declaration expected-token grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Delimited_List_And_End_Recovery", "malformed metadata-list and end-boundary expected-token grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Implicit_Begin_Recovery", "implicit begin grammar recovery before handled statement sequences");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Subprogram_And_Concurrent_Declaration_Recovery", "malformed subprogram and concurrent declaration-header recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Declaration_After_Begin_Recovery", "declaration after begin grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_EOF_Statement_Part_Recovery", "EOF handled-statement-part grammar recovery");
      Require_Syntax_Test ("Test_Language_Model_Syntax_Tree_Private_Parts_Own_Declarations", "private-part syntax-tree ownership");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Ada_Grammar", "token-cursor Ada grammar layer");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Grammar_Completeness_Details", "token-cursor detailed Ada grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Metadata_Grammar_Completeness", "token-cursor metadata and representation grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Context_And_Label_Grammar_Completeness", "token-cursor context and label grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Separate_And_Body_Stub_Grammar_Completeness", "token-cursor separate subunit and body-stub grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Concurrent_Grammar_Completeness", "token-cursor concurrent definition and entry-family grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Entry_Index_And_Accept_Grammar", "token-cursor entry-index and accept grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Task_Protected_Type_Header_Grammar_Completeness", "token-cursor task/protected type header grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Expression_Grammar_Completeness", "token-cursor allocator membership delta reduction and short-circuit expression productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Generic_Formal_Grammar_Completeness", "token-cursor generic formal grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Subprogram_Modifier_Grammar_Completeness", "token-cursor subprogram modifier grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Defining_Name_And_Operator_Grammar_Completeness", "token-cursor defining-name and operator-symbol grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Context_Modifier_Grammar_Completeness", "token-cursor limited/private with-clause grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Representation_Clause_Grammar_Completeness", "token-cursor representation-clause grammar productions");
      Require_Syntax_Test ("Test_Language_Model_Representation_Static_Expressions_Are_Evaluated", "bounded static representation-expression evaluation");
      Require_Syntax_Test ("Test_Language_Model_Representation_Based_Exponent_Expressions", "based literal exponent representation-expression evaluation");
      Require_Marker (Test_Body, "expected =>", "expected-arrow malformed-alternative recovery regression coverage");
      Require_Marker (Test_Body, "malformed declaration", "malformed-declaration recovery regression coverage");
      Require_Marker (Test_Body, "Node_Implicit_Begin", "implicit begin recovery regression coverage");
      Require_Marker (Test_Body, "Node_Unexpected_Declaration", "declaration-after-begin recovery regression coverage");
      Require_Marker (Test_Body, "nested declare", "nested-declare recovery guidance coverage");
      Require_Marker (Test_Body, "Node_Implicit_End", "implicit statement-part and generic formal-part recovery regression coverage");
      Require_Marker (Test_Body, "at end of file", "EOF implicit statement-part recovery regression coverage");
      Require_Marker (Test_Body, "generic formal part", "generic formal-part recovery regression coverage");
      Require_Marker (Test_Body, "Node_End_Target", "named end-target regression coverage");
      Require_Marker (Test_Body, "Node_Expected_End_Target", "expected named end-target regression coverage");
      Require_Marker (Test_Body, "expected begin", "expected-begin malformed handled sequence regression coverage");
      Require_Marker (Test_Body, "malformed subprogram/concurrent bodies", "malformed subprogram and concurrent expected-is recovery coverage");
      Require_Marker (Test_Body, "malformed subprogram/task/protected declarations", "malformed subprogram and concurrent expected-semicolon recovery coverage");
      Require_Marker (Test_Body, "Node_Expected_Token", "expected-token malformed-header regression coverage");
      Require_Marker (Test_Body, "malformed end boundary", "malformed end-boundary recovery regression coverage");
      Require_Marker (Test_Body, "malformed delimited list", "malformed delimited-list recovery regression coverage");
      Require_Marker (Test_Body, "Node_Missing_End", "missing-end recovery regression coverage");
      Require_Marker (Test_Body, "Hidden_Value", "private-part declaration ownership regression coverage");
      Require_Marker (Test_Body, "private-part scope", "private-part implicit closure regression coverage");
      Require_Marker (Test_Body, "Node_Token_Cursor_Grammar", "token-cursor grammar syntax-tree regression coverage");
      Require_Marker (Test_Body, "Production_Simple_Expression", "token-cursor expression-precedence regression coverage");
      Require_Marker (Test_Body, "Production_Membership_Choice_List", "token-cursor membership-choice regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Membership_Range_Grammar_Completeness", "token-cursor membership range-choice regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Target_Name_Grammar_Completeness", "token-cursor Ada 2022 target-name regression coverage");
      Require_Marker (Test_Body, "Natural range 20 .. 30", "token-cursor membership subtype-range regression source");
      Require_Marker (Test_Body, "Production_Short_Circuit_Operation", "token-cursor short-circuit regression coverage");
      Require_Marker (Test_Body, "Production_Allocator", "token-cursor allocator regression coverage");
      Require_Marker (Test_Body, "Production_Delta_Aggregate", "token-cursor delta aggregate regression coverage");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness", "token-cursor aggregate association depth");
      Require_Marker (Test_Body, "Production_Reduction_Expression", "token-cursor reduction expression regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Box_Expression_Grammar_Completeness", "token-cursor box-expression regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Incomplete_Type_Grammar_Completeness", "token-cursor incomplete type regression coverage");
      Require_Marker (Test_Body, "type Root is tagged;", "token-cursor tagged incomplete type regression source");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Attribute_Argument_Grammar_Completeness", "token-cursor attribute argument-part regression coverage");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Attribute_Depth_Grammar_Completeness", "token-cursor attribute grammar depth");
      Require_Syntax_Test ("Test_Analysis_Binding_Semantic_Colouring_Precision", "semantic-colouring executable binding precision");
      Require_Syntax_Test ("Test_Phase722_Semantic_Colouring_Expanded_Grammar_Precision", "semantic-colouring expanded grammar precision");
      Require_Marker (Semantics_Source, "Binding_Qualified_Expression_Target", "semantic-colouring qualified-expression target precision");
      Require_Marker (Semantics_Source, "Binding_Selected_Component", "semantic-colouring unresolved selected-component degradation");
      Require_Marker (Semantics_Source, "Binding_Generic_Actual_Selector", "semantic-colouring generic actual selector degradation");
      Require_Marker (Semantics_Source, "Binding_Aggregate_Component_Selector", "semantic-colouring aggregate component selector degradation");
      Require_Marker (Semantics_Source, "Binding_Return_Object_Defining_Name", "semantic-colouring extended-return object defining name precision");
      Require_Marker (Outline_Source, "variant record type", "outline variant-record label precision");
      Require_Marker (Outline_Source, "entry family", "outline entry-family label precision");
      Require_Marker (Outline_Tests, "Test_Phase707_Ada_Outline_Precision_For_Expanded_Constructs", "outline precision regression coverage");
      Require_Marker (Outline_Source, "Type_Label_Prefix", "outline type-family label precision helper");
      Require_Marker (Outline_Source, "Formal_Type_Label_Prefix", "outline formal type-family label precision helper");
      Require_Marker (Outline_Source, "access subprogram type", "outline access-subprogram type label precision");
      Require_Marker (Outline_Source, "formal array type", "outline formal array type label precision");
      Require_Marker (Outline_Tests, "Test_Phase721_Ada_Outline_Type_Family_Label_Precision", "outline type family label precision regression coverage");
      Require_Marker (Test_Body, "Values'First (1)", "token-cursor attribute argument regression source");
      Require_Marker (Test_Body, "Production_Record_Definition", "token-cursor record grammar regression coverage");
      Require_Marker (Test_Body, "Production_Conditional_Expression", "token-cursor conditional expression regression coverage");
      Require_Marker (Test_Body, "Production_Extended_Return_Statement", "token-cursor extended-return regression coverage");
      Require_Marker (Test_Body, "Production_Select_Alternative", "token-cursor select-alternative regression coverage");
      Require_Marker (Test_Body, "Production_Loop_Parameter_Specification", "token-cursor loop-parameter regression coverage");
      Require_Marker (Test_Body, "Production_Iterator_Specification", "token-cursor iterator-loop regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Quantified_Expression_Grammar_Completeness", "token-cursor quantified-expression loop-scheme regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Declare_Expression_Grammar_Completeness", "token-cursor declare-expression regression coverage");
      Require_Marker (Test_Body, "Production_Declare_Expression", "token-cursor declare-expression production regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Aggregate_Iterator_Grammar_Completeness", "token-cursor aggregate iterator regression coverage");
      Require_Marker (Test_Body, "Production_Iterated_Component_Association", "token-cursor aggregate iterated association production coverage");
      Require_Marker (Test_Body, "Production_Task_Type_Declaration", "token-cursor task type production regression coverage");
      Require_Marker (Test_Body, "Production_Protected_Type_Declaration", "token-cursor protected type production regression coverage");
      Require_Marker (Test_Body, "Production_Array_Type_Definition", "token-cursor array type-definition regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Array_Index_Subtype_Grammar_Completeness", "token-cursor unconstrained array index subtype regression coverage");
      Require_Marker (Test_Body, "Production_Index_Subtype_Definition", "token-cursor index subtype-definition production coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Null_Exclusion_Access_Grammar_Completeness", "token-cursor null-exclusion access regression coverage");
      Require_Marker (Test_Body, "Production_Null_Exclusion", "token-cursor null-exclusion production coverage");
      Require_Marker (Test_Body, "Production_Access_Type_Definition", "token-cursor access type-definition regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Type_Modifier_Grammar_Completeness", "token-cursor modified type-definition regression coverage");
      Require_Marker (Test_Body, "Production_Type_Modifier", "token-cursor type modifier production coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Delay_Statement_Grammar_Completeness", "token-cursor delay statement regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Return_Object_Declaration", "token-cursor extended return object grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Extended_Return_Initializer", "token-cursor extended return initializer grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Return_Object_Defining_Name", "token-cursor extended return defining-name grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Return_Object_Subtype_Indication", "token-cursor extended return subtype grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Return_Object_Initializer", "token-cursor extended return object initializer grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Extended_Return_Do_Keyword", "token-cursor extended return do-boundary grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Extended_Return_End_Return", "token-cursor extended return end-boundary grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Extended_Return_Missing_Do_Recovery_Boundary", "token-cursor extended return missing-do recovery grammar production");
      Require_Marker (Token_Cursor_Body, "Production_Extended_Return_Missing_Do_Recovery_Boundary", "token-cursor extended return missing-do recovery implementation");
      Require_Marker (Token_Cursor_Spec, "Production_Return_Recovery_Boundary", "token-cursor return recovery-boundary grammar production");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Extended_Return_Grammar_Completeness", "token-cursor extended return object regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Return_Statement_Depth_Grammar_Completeness", "token-cursor return statement depth regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Extended_Return_Do_Recovery_Pass865", "token-cursor extended return missing-do regression coverage");
      Require_Marker (Test_Body, "return Broken : Item;", "token-cursor malformed extended return recovery regression source");
      Require_Marker (Test_Body, "return Result : aliased constant Item := Make_Item", "token-cursor extended return regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Null_Statement_Terminator", "token-cursor null statement terminator grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exit_When_Keyword", "token-cursor exit when-keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exit_Recovery_Boundary", "token-cursor exit recovery-boundary grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Goto_Recovery_Boundary", "token-cursor goto recovery-boundary grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Goto_Missing_Target_Recovery_Boundary", "token-cursor goto missing-target recovery grammar production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Goto_Target_Recovery_Pass861", "token-cursor goto missing-target regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Delay_Mode_Keyword", "token-cursor delay mode-keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Delay_Recovery_Boundary", "token-cursor delay recovery-boundary grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Delay_Until_Missing_Expression_Recovery_Boundary", "token-cursor delay-until missing-expression recovery grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Delay_Relative_Missing_Expression_Recovery_Boundary", "token-cursor relative-delay missing-expression recovery grammar production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Delay_Expression_Recovery_Pass851", "token-cursor delay expression recovery regression coverage");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Exit_Goto_Null_Delay_Statement_Depth_Grammar_Completeness", "token-cursor exit/goto/null/delay depth regression coverage");
      Require_Marker (Test_Body, "exit when;", "token-cursor malformed exit-when recovery regression source");
      Require_Marker (Test_Body, "delay;", "token-cursor malformed delay recovery regression source");
      Require_Marker (Test_Body, "goto;", "token-cursor malformed goto recovery regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Accept_Missing_Terminator_Recovery_Boundary", "token-cursor accept missing-terminator recovery grammar production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery_Pass853", "token-cursor accept missing-terminator regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Accept_Missing_Entry_Name_Recovery_Boundary", "token-cursor accept missing-entry-name recovery grammar production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Accept_Entry_Name_Recovery_Pass863", "token-cursor accept missing-entry-name regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Requeue_Target", "token-cursor requeue target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Requeue_Selected_Target", "token-cursor selected requeue target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Requeue_Indexed_Target", "token-cursor indexed requeue target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Requeue_With_Abort", "token-cursor requeue with-abort grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Requeue_Missing_Terminator_Recovery_Boundary", "token-cursor requeue missing-terminator recovery grammar production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery_Pass852", "token-cursor requeue missing-terminator regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Requeue_Target_Recovery_Boundary", "token-cursor requeue target recovery-boundary grammar production");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Requeue_Grammar_Completeness", "token-cursor requeue target regression coverage");
      Require_Marker (Test_Body, "requeue Server.Queue (Index) with abort", "token-cursor requeue target regression source");
      Require_Marker (Test_Body, "requeue;", "token-cursor malformed requeue recovery regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Abort_Target", "token-cursor abort target grammar production");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Abort_Statement_Grammar_Completeness", "token-cursor abort target list regression coverage");
      Require_Marker (Test_Body, "abort Worker, Pool.Tasks (Index), Controller.Current.all", "token-cursor abort target list regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Choice_Parameter", "token-cursor exception choice parameter grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Choice_List", "token-cursor exception choice list grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Choice", "token-cursor exception choice grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Reraise_Statement", "token-cursor bare raise grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Raise_With_Message", "token-cursor raise-with-message grammar production");
      Require_Marker (Token_Cursor_Body, "bare raise statement", "token-cursor bare raise statement parser path");
      Require_Marker (Token_Cursor_Body, "raise with message", "token-cursor raise-with-message parser path");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Raise_Statement_Grammar_Completeness", "token-cursor raise statement grammar coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Exit_Target", "token-cursor exit target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exit_When_Condition", "token-cursor exit when-condition grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exit_When_Missing_Condition_Recovery_Boundary", "token-cursor exit-when missing-condition recovery grammar production");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Exit_When_Condition_Recovery_Pass850", "token-cursor exit-when missing-condition regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Goto_Target", "token-cursor goto target grammar production");
      Require_Marker (Token_Cursor_Body, "exit loop name", "token-cursor exit target parser path");
      Require_Marker (Token_Cursor_Body, "exit when condition", "token-cursor exit condition parser path");
      Require_Marker (Token_Cursor_Body, "goto target", "token-cursor goto target parser path");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Exit_Goto_Grammar_Completeness", "token-cursor exit/goto statement grammar coverage");
      Require_Marker (Syntax_Tests, "exit Main when Done", "token-cursor exit target regression source");
      Require_Marker (Syntax_Tests, "goto Finished", "token-cursor goto target regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Select_Guard", "token-cursor select guard grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Select_Else_Part", "token-cursor select else grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Terminate_Alternative", "token-cursor terminate alternative grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Abortable_Part", "token-cursor abortable part grammar production");
      Require_Marker (Token_Cursor_Body, "select guard", "token-cursor select guard parser path");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Select_Alternative_Grammar_Completeness", "token-cursor select alternative grammar coverage");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Box_Expression_Grammar_Completeness", "token-cursor box-expression grammar coverage");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Incomplete_Type_Grammar_Completeness", "token-cursor incomplete type grammar coverage");
      Require_Marker (Syntax_Tests, "Test_Language_Model_Token_Cursor_Attribute_Argument_Grammar_Completeness", "token-cursor attribute argument grammar coverage");
      Require_Marker (Syntax_Tests, "when Ready =>", "token-cursor select guard regression source");
      Require_Marker (Syntax_Tests, "then abort", "token-cursor asynchronous select regression source");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Exception_Handler_Grammar_Completeness", "token-cursor exception handler regression coverage");
      Require_Marker (Test_Body, "when Failure : Constraint_Error | Program_Error", "token-cursor exception choice parameter regression source");
      Require_Marker (Test_Body, "Production_Delay_Until_Statement", "token-cursor delay until production coverage");
      Require_Marker (Test_Body, "Production_Delay_Relative_Statement", "token-cursor delay relative production coverage");
      Require_Marker (Test_Body, "delay until Clock", "token-cursor delay until regression source");
      Require_Marker (Test_Body, "synchronized interface", "token-cursor interface modifier regression source");
      Require_Marker (Test_Body, "abstract tagged limited record", "token-cursor tagged limited record modifier regression source");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Profile_Item_Grammar_Completeness", "token-cursor structured profile item regression coverage");
      Require_Marker (Test_Body, "Production_Parameter_Mode", "token-cursor parameter-mode production coverage");
      Require_Marker (Test_Body, "Production_Aliased_Part", "token-cursor aliased profile production coverage");
      Require_Marker (Test_Body, "Production_Default_Expression", "token-cursor profile default-expression production coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Object_Qualifier", "token-cursor object qualifier grammar production");
      Require_Marker (Token_Cursor_Body, "aliased object", "token-cursor aliased object qualifier parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Object_Qualifier_Grammar_Completeness", "token-cursor object qualifier regression coverage");
      Require_Marker (Test_Body, "aliased constant Item", "token-cursor aliased constant object regression source");
      Require_Marker (Test_Body, "aliased not null access Item", "token-cursor aliased access object regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Unknown_Discriminant_Part", "token-cursor unknown discriminant grammar production");
      Require_Marker (Token_Cursor_Body, "unknown discriminant part", "token-cursor unknown discriminant parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Unknown_Discriminant_Grammar_Completeness", "token-cursor unknown discriminant regression coverage");
      Require_Marker (Test_Body, "type Visible (<>) is private", "token-cursor private type unknown discriminant regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Digits_Constraint", "token-cursor digits constraint grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Delta_Constraint", "token-cursor delta constraint grammar production");
      Require_Marker (Token_Cursor_Body, "digits constraint", "token-cursor digits constraint parser path");
      Require_Marker (Token_Cursor_Body, "delta constraint", "token-cursor delta constraint parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Subtype_Constraint_Grammar_Completeness", "token-cursor subtype numeric constraint regression coverage");
      Require_Marker (Test_Body, "subtype Small_Money is Money delta", "token-cursor fixed-point subtype constraint regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Component_Definition", "token-cursor component definition grammar production");
      Require_Marker (Token_Cursor_Body, "component definition", "token-cursor component-definition parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Component_Definition_Grammar_Completeness", "token-cursor component definition regression coverage");
      Require_Marker (Test_Body, "Left, Right : aliased not null access Node", "token-cursor aliased access component regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Constraint", "token-cursor discriminant constraint grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Association", "token-cursor discriminant association grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Discriminant_Selector_Name", "token-cursor discriminant selector-name grammar production");
      Require_Marker (Token_Cursor_Body, "Parse_Discriminant_Selector_Name_List", "token-cursor discriminant selector-name-list parser path");
      Require_Marker (Token_Cursor_Body, "discriminant constraint", "token-cursor discriminant-constraint parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness", "token-cursor discriminant constraint regression coverage");
      Require_Marker (Test_Body, "Low | High => 1", "token-cursor discriminant selector-list regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Aspect_Mark", "token-cursor aspect mark grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Classwide_Aspect_Mark", "token-cursor class-wide aspect mark grammar production");
      Require_Marker (Token_Cursor_Body, "Aspect'Class", "token-cursor class-wide aspect mark parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Aspect_Mark_Grammar_Completeness", "token-cursor aspect mark regression coverage");
      Require_Marker (Test_Body, "Type_Invariant'Class", "token-cursor class-wide aspect mark regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Mod_Clause", "token-cursor record representation mod clause grammar production");
      Require_Marker (Token_Cursor_Body, "record representation mod clause", "token-cursor record representation mod-clause parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Record_Representation_Mod_Clause_Grammar_Completeness", "token-cursor record representation mod-clause regression coverage");
      Require_Marker (Test_Body, "at mod 8", "token-cursor record representation mod-clause regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Object_Mode", "token-cursor generic formal object mode grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Object_Default", "token-cursor generic formal object default grammar production");
      Require_Marker (Token_Cursor_Body, "formal object declaration", "token-cursor generic formal object parser path");
      Require_Marker (Test_Body, "Defaulted, Second : in out Element := <>", "token-cursor generic formal object default regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Subprogram_Default_Box", "token-cursor formal subprogram box default grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Subprogram_Default_Null", "token-cursor formal subprogram null default grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Subprogram_Default_Abstract", "token-cursor formal subprogram abstract default grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Formal_Subprogram_Default_Name", "token-cursor formal subprogram name default grammar production");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Formal_Subprogram_Default_Grammar_Completeness", "token-cursor formal subprogram default regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Formal_Selector", "token-cursor generic actual formal selector grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Box", "token-cursor generic actual box grammar production");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Generic_Actual_Box_Grammar_Completeness", "token-cursor generic actual selector and box regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Package_Instantiation", "token-cursor generic package instantiation grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Procedure_Instantiation", "token-cursor generic procedure instantiation grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Function_Instantiation", "token-cursor generic function instantiation grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Nested_Actual_Part", "token-cursor nested generic actual grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Generic_Actual_Recovery_Boundary", "token-cursor generic actual recovery-boundary grammar production");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Generic_Instantiation_Depth_Grammar_Completeness", "token-cursor generic instantiation depth regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Unconstrained_Array_Index_Part", "token-cursor unconstrained array index part grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Constrained_Array_Index_Part", "token-cursor constrained array index part grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Array_Component_Access_Definition", "token-cursor anonymous access array component grammar production");
      Require_Marker (Token_Cursor_Body, "array component access definition", "token-cursor array component access parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Array_Type_Depth_Grammar_Completeness", "token-cursor array type depth regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Access_Pool_Specific_Object", "token-cursor pool-specific access object grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Access_General_Object", "token-cursor general access object grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Access_Object_Subtype_Mark", "token-cursor access object subtype-mark grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Access_Named_Subprogram_Definition", "token-cursor named access-to-subprogram grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Access_Type_Recovery_Boundary", "token-cursor access type recovery-boundary grammar production");
      Require_Marker (Token_Cursor_Body, "access object subtype mark", "token-cursor access object subtype parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Access_Type_Depth_Grammar_Completeness", "token-cursor access type depth regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Abstract_Type_Modifier", "token-cursor abstract type modifier grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Tagged_Type_Modifier", "token-cursor tagged type modifier grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Derived_Private_Extension", "token-cursor derived private extension grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Derived_Record_Extension", "token-cursor derived record extension grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Derived_Null_Record_Extension", "token-cursor derived null record extension grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Derived_Type_Recovery_Boundary", "token-cursor derived type recovery-boundary grammar production");
      Require_Marker (Token_Cursor_Body, "derived null record extension", "token-cursor derived null record extension parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Derived_Tagged_Extension_Depth_Grammar_Completeness", "token-cursor derived/tagged extension depth regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Pragma_Argument_Identifier", "token-cursor pragma argument identifier grammar production");
      Require_Marker (Token_Cursor_Body, "pragma_argument_identifier", "token-cursor named pragma argument parser path");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Pragma_Argument_Identifier_Grammar_Completeness", "token-cursor named pragma argument regression coverage");
      Require_Marker (Test_Body, "Condition => Is_Ready", "token-cursor named pragma argument regression source");
      Require_Marker (Token_Cursor_Spec, "Production_Component_Association", "token-cursor aggregate component association grammar production");
      Require_Marker (Token_Cursor_Body, "Has_Top_Level_Arrow_Before_Association_End", "token-cursor aggregate association choice-list detection");
      Require_Marker (Test_Body, "Test_Language_Model_Token_Cursor_Aggregate_Component_Association_Grammar_Completeness", "token-cursor aggregate component association regression coverage");
      Require_Marker (Test_Body, "A | B => 1", "token-cursor aggregate choice-list regression source");
      Require_Marker (Test_Body, "with procedure No_Op is null", "token-cursor formal subprogram null default regression source");
      Require_Marker (Test_Body, "Production_Range_Constraint", "token-cursor subtype/range constraint regression coverage");
      Require_Marker (Test_Body, "Production_Pragma_Argument_Association", "token-cursor pragma argument regression coverage");
      Require_Marker (Test_Body, "Production_Aspect_Association", "token-cursor aspect association regression coverage");
      Require_Marker (Test_Body, "Production_Generic_Actual_Association", "token-cursor generic actual regression coverage");
      Require_Marker (Test_Body, "Production_Attribute_Definition_Clause", "token-cursor attribute definition-clause regression coverage");
      Require_Marker (Test_Body, "Production_Enumeration_Representation_Clause", "token-cursor enumeration representation-clause regression coverage");
      Require_Marker (Test_Body, "Production_Address_Clause", "token-cursor address-clause regression coverage");
      Require_Marker (Test_Body, "Production_Representation_Component_Clause", "token-cursor representation component regression coverage");
      Require_Marker (Test_Body, "Production_Package_Body_Stub", "token-cursor body-stub regression coverage");
      Require_Marker (Test_Body, "Node_Recovery_Point", "recovery-point regression coverage");
      Require_Marker (Test_Body, "Node_Mismatched_End", "mismatched alternative recovery regression coverage");
      Require_Marker (Test_Body, "Node_Deferred_Constant_Declaration", "deferred constant declaration regression coverage");
      Require_Marker (Test_Body, "Node_Constant_Declaration", "typed constant declaration regression coverage");
      Require_Syntax_Test ("Test_Generic_Formal_Package_Target_Metadata", "generic formal packages");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Formal_Package_Contract_Edge_Cases", "formal package generic contract edge cases");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Formal_Package_Defaulted_Actuals", "defaulted formal package actual parts");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Formal_Package_Hostile_Recovery_Pass784", "formal package hostile recovery");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Record_Representation_Recovery_Pass785", "record representation recovery depth");
      Require_Token_Cursor_Production ("Production_Exception_Handler_Missing_Arrow_Recovery_Boundary", "exception handler missing-arrow recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Arrow_Pass786", "exception handler missing-arrow recovery depth");
      Require_Token_Cursor_Production ("Production_Select_Guard_Missing_Arrow_Recovery_Boundary", "select guard missing-arrow recovery depth");
      Require_Token_Cursor_Production ("Production_Select_Guard_Missing_Condition_Recovery_Boundary", "select guard missing-condition recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Select_Guard_Missing_Arrow_Pass787", "select guard missing-arrow recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Select_Guard_Condition_Recovery_Pass854", "select guard missing-condition recovery depth");
      Require_Token_Cursor_Production ("Production_Accept_End_Keyword", "accept end keyword depth");
      Require_Token_Cursor_Production ("Production_Accept_End_Name", "accept end name depth");
      Require_Token_Cursor_Production ("Production_Accept_Terminator", "accept terminator depth");
      Require_Token_Cursor_Production ("Production_Accept_Missing_Entry_Name_Recovery_Boundary", "accept missing-entry-name recovery depth");
      Require_Token_Cursor_Production ("Production_Accept_Missing_End_Recovery_Boundary", "accept missing-end recovery depth");
      Require_Token_Cursor_Production ("Production_Accept_Body_Missing_Statement_Recovery_Boundary", "accept body missing-statement recovery depth");
      Require_Token_Cursor_Production ("Production_Accept_Body_End_Statement_Recovery_Boundary", "accept body end-statement recovery depth");
      Require_Token_Cursor_Production ("Production_Formal_Incomplete_Type_Declaration", "generic formal incomplete type grammar depth");
      Require_Token_Cursor_Production ("Production_Formal_Incomplete_Tagged_Type_Definition", "generic formal tagged incomplete type grammar depth");
      Require_Token_Cursor_Production ("Production_Formal_Incomplete_Type_Recovery_Boundary", "generic formal incomplete type recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Accept_Entry_Name_Recovery_Pass863", "accept missing-entry-name recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Accept_End_Recovery_Pass788", "accept end and missing-end recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Accept_Body_Statement_Recovery_Pass883", "accept body missing-statement recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Generic_Formal_Incomplete_Type_Pass884", "generic formal incomplete type grammar depth");
      Require_Token_Cursor_Production ("Production_Timed_Entry_Call_Statement", "timed entry-call select statement depth");
      Require_Token_Cursor_Production ("Production_Timed_Entry_Call_Entry_Call_Part", "timed entry-call part depth");
      Require_Token_Cursor_Production ("Production_Conditional_Entry_Call_Statement", "conditional entry-call select statement depth");
      Require_Token_Cursor_Production ("Production_Conditional_Entry_Call_Entry_Call_Part", "conditional entry-call part depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Timed_Conditional_Entry_Call_Pass789", "timed and conditional entry-call select depth");
      Require_Token_Cursor_Production ("Production_Requeue_Terminator", "requeue terminator depth");
      Require_Token_Cursor_Production ("Production_Requeue_With_Missing_Abort_Recovery_Boundary", "requeue missing-abort recovery depth");
      Require_Token_Cursor_Production ("Production_Requeue_Missing_Target_Recovery_Boundary", "requeue missing-target recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Requeue_Recovery_Pass790", "requeue terminator and missing-abort recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Requeue_Target_Recovery_Pass864", "requeue missing-target recovery depth");
      Require_Token_Cursor_Production ("Production_Terminate_Terminator", "terminate alternative terminator depth");
      Require_Token_Cursor_Production ("Production_Terminate_Missing_Terminator_Recovery_Boundary", "terminate alternative missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Terminate_Alternative_Recovery_Pass791", "terminate alternative terminator and recovery depth");
      Require_Token_Cursor_Production ("Production_Abort_Terminator", "abort statement terminator depth");
      Require_Token_Cursor_Production ("Production_Abort_Missing_Terminator_Recovery_Boundary", "abort missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Abort_Terminator_Recovery_Pass792", "abort terminator and missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Delay_Missing_Terminator_Recovery_Boundary", "delay missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Return_Terminator", "return terminator depth");
      Require_Token_Cursor_Production ("Production_Return_Missing_Terminator_Recovery_Boundary", "return missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Pass856", "return missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Extended_Return_Missing_End_Recovery_Boundary", "extended return missing-end recovery depth");
      Require_Token_Cursor_Production ("Production_Raise_Terminator", "raise statement terminator depth");
      Require_Token_Cursor_Production ("Production_Raise_Missing_Terminator_Recovery_Boundary", "raise missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Exit_Terminator", "exit statement terminator depth");
      Require_Token_Cursor_Production ("Production_Exit_Missing_Terminator_Recovery_Boundary", "exit missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Goto_Terminator", "goto statement terminator depth");
      Require_Token_Cursor_Production ("Production_Goto_Missing_Terminator_Recovery_Boundary", "goto missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Null_Missing_Terminator_Recovery_Boundary", "null missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Assignment_Terminator", "assignment statement terminator depth");
      Require_Token_Cursor_Production ("Production_Assignment_Missing_Terminator_Recovery_Boundary", "assignment missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Call_Terminator", "call statement terminator depth");
      Require_Token_Cursor_Production ("Production_Call_Missing_Terminator_Recovery_Boundary", "call missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Entry_Terminator", "entry declaration terminator depth");
      Require_Token_Cursor_Production ("Production_Entry_Missing_Terminator_Recovery_Boundary", "entry declaration missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Entry_Body_Begin_Keyword", "entry body begin keyword depth");
      Require_Token_Cursor_Production ("Production_Entry_Body_End_Keyword", "entry body end keyword depth");
      Require_Token_Cursor_Production ("Production_Entry_Body_End_Name", "entry body end name depth");
      Require_Token_Cursor_Production ("Production_Entry_Body_End_Terminator", "entry body end terminator depth");
      Require_Token_Cursor_Production ("Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary", "entry body missing-end recovery depth");
      Require_Token_Cursor_Production ("Production_Subprogram_Declaration_Terminator", "subprogram declaration terminator depth");
      Require_Token_Cursor_Production ("Production_Subprogram_Declaration_Missing_Terminator_Recovery_Boundary", "subprogram declaration missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Object_Declaration_Terminator", "object declaration terminator depth");
      Require_Token_Cursor_Production ("Production_Object_Declaration_Missing_Terminator_Recovery_Boundary", "object declaration missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Type_Declaration_Terminator", "type declaration terminator depth");
      Require_Token_Cursor_Production ("Production_Type_Declaration_Missing_Terminator_Recovery_Boundary", "type declaration missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Subtype_Declaration_Terminator", "subtype declaration terminator depth");
      Require_Token_Cursor_Production ("Production_Subtype_Declaration_Missing_Terminator_Recovery_Boundary", "subtype declaration missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_If_End_Terminator", "if compound end terminator depth");
      Require_Token_Cursor_Production ("Production_If_Missing_End_Terminator_Recovery_Boundary", "if compound end missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Loop_End_Terminator", "loop compound end terminator depth");
      Require_Token_Cursor_Production ("Production_Loop_Missing_End_Terminator_Recovery_Boundary", "loop compound end missing-terminator recovery depth");
      Require_Token_Cursor_Production ("Production_Block_End_Terminator", "block compound end terminator depth");
      Require_Token_Cursor_Production ("Production_Block_Missing_End_Terminator_Recovery_Boundary", "block compound end missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Compound_End_Terminator_Recovery_Pass801", "compound end terminator and missing-semicolon recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Delay_Terminator_Recovery_Pass793", "delay terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Raise_Terminator_Recovery_Pass795", "raise terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Exit_Terminator_Recovery_Pass796", "exit terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Goto_Terminator_Recovery_Pass797", "goto terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Null_Terminator_Recovery_Pass798", "null terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Assignment_Terminator_Recovery_Pass799", "assignment terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Call_Terminator_Recovery_Pass800", "call terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Entry_Declaration_Terminator_Recovery_Pass808", "entry declaration terminator and recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Entry_Body_End_Recovery_Pass809", "entry body end and missing-end recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Subprogram_Declaration_Terminator_Pass810", "subprogram declaration terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Object_Declaration_Terminator_Pass811", "object declaration terminator and missing-terminator recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Type_Subtype_Declaration_Terminator_Pass812", "type and subtype declaration terminator and recovery depth");
      Require_Syntax_Test ("Test_Language_Model_Formal_Package_Actuals_Project_Into_Model", "formal package actual projection into language model");
      Require_Syntax_Test ("Test_Language_Model_Formal_Package_Actuals_Feed_Resolver_View", "formal package actuals feed resolver and type inference");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Renaming_Declaration_Grammar_Completeness", "token-cursor renaming declaration grammar completeness");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Renaming_Target_Depth_Grammar_Completeness", "token-cursor renaming target grammar depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness", "token-cursor name-family grammar refinements");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Expression_Name_Edge_Recovery", "token-cursor expression and name edge recovery");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Variant_Record_Depth_Grammar_Completeness", "token-cursor variant record grammar depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Case_Statement_Choice_Depth_Grammar_Completeness", "token-cursor case statement choice grammar depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_If_Statement_Branch_Grammar_Completeness", "token-cursor if statement grammar depth");
      Require_Marker (Token_Cursor_Spec, "Production_If_Statement_Then_Keyword", "if statement then keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Elsif_Statement_Branch", "elsif branch grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Elsif_Statement_Then_Keyword", "elsif then keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_If_Statement_Else_Branch", "if statement else branch grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_If_Statement_End_Keyword", "if statement end keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_If_Statement_Recovery_Boundary", "if statement recovery boundary grammar production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Entry_Select_Depth_Grammar_Completeness", "token-cursor entry/select grammar depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Select_Statement_Alternative_Depth", "token-cursor select statement alternative depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Loop_Block_Declare_Depth_Grammar_Completeness", "token-cursor loop/block/declare grammar depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Body_Stub_Separate_Subunit_Depth_Grammar_Completeness", "token-cursor body stub separate subunit grammar depth");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Subprogram_Body_Declarative_Part_Depth_Grammar_Completeness", "token-cursor subprogram body declarative-part grammar depth");
      Require_Marker (Token_Cursor_Spec, "Production_Subprogram_Body_Declarative_Item", "subprogram body declarative item grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Subprogram_Body_Begin_Keyword", "subprogram body begin keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Subprogram_Body_End_Keyword", "subprogram body end keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Subprogram_Body_Recovery_Boundary", "subprogram body recovery boundary grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Parent_Unit_Name", "separate parent unit name grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Body_Declaration", "separate nested body declaration grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Subprogram_Body", "separate subprogram body grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Package_Body", "separate package body grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Body_Stub_Separate_Keyword", "body stub separate keyword grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Task_Body", "separate task body grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Protected_Body", "separate protected body grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Separate_Entry_Body", "separate entry body grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Statement_Identifier", "statement identifier grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Named_Loop_Statement", "named loop statement grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Named_Block_Statement", "named block statement grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Loop_Iterator_Filter", "loop iterator filter grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Loop_Iterator_Filter_Condition", "loop iterator filter condition grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Parallel_Loop_Statement", "parallel loop statement grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Parallel_Loop_Chunk_Specification", "parallel loop chunk specification grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Parallel_Loop_Iteration_Scheme", "parallel loop iteration-scheme grammar production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Parallel_Loop_Depth_Pass779", "token-cursor parallel loop grammar depth");
      Require_Marker (Token_Cursor_Spec, "Production_Asynchronous_Select_Statement", "asynchronous select statement grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Asynchronous_Select_Triggering_Alternative", "asynchronous select triggering alternative grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Asynchronous_Select_Delay_Trigger", "asynchronous select delay trigger grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Asynchronous_Select_Abortable_Part", "asynchronous select abortable part grammar production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Asynchronous_Select_Depth_Pass780", "token-cursor asynchronous select grammar depth");
      Require_Marker (Token_Cursor_Spec, "Production_Loop_Begin_Keyword", "loop begin keyword grammar production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Loop_Iteration_Scheme_Metadata", "token-cursor loop iteration scheme metadata");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Entry_Family_Index_Depth", "token-cursor entry family index depth metadata");
      Require_Marker (Token_Cursor_Spec, "Production_Loop_End_Name", "loop end-name grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Block_End_Name", "block end-name grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Declare_Block_Statement", "declare block grammar production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Exception_Depth_Grammar_Completeness", "token-cursor exception grammar depth");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Renaming_Target", "exception-renaming target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Handler_Local_Name", "exception handler local-name grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Choice_Arrow", "exception choice arrow grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Exception_Others_Choice", "exception others choice grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Raise_Statement_Target", "raise-statement target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary", "raise-statement missing exception-name recovery grammar production");
      Require_Syntax_Test ("Test_Language_Model_Token_Cursor_Raise_Statement_Exception_Name_Recovery_Pass862", "token-cursor raise statement missing exception-name recovery regression coverage");
      Require_Marker (Token_Cursor_Spec, "Production_Raise_Expression_Target", "raise-expression target grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Raise_Expression_Message", "raise-expression message grammar production");
      Require_Syntax_Test ("Test_Language_Model_Legality_Profile_Parameter_Pass", "language model checks duplicate profile parameter legality");
      Require_Marker (Token_Cursor_Spec, "Production_Selected_Name_Prefix", "selected-name prefix grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Selected_Literal_Selector", "selected literal selector grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Allocator_Subtype_Mark", "allocator subtype-mark grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Allocator_Access_Subtype", "allocator access-subtype grammar production");
      Require_Marker (Token_Cursor_Spec, "Production_Qualified_Expression_Apostrophe", "qualified-expression apostrophe grammar production");

      Require_Outline_Test ("Test_Phase579_Outline_Marker_Fallback_Is_Marker_Only", "marker-only Outline fallback");
      Require_Outline_Test ("Test_Phase579_Outline_Parser_Runs_For_Extensionless_Buffer", "extensionless parser-backed Outline");
      Require_Outline_Test ("Test_Phase579_Ada_Representation_Clauses_Are_Detail_Metadata", "representation metadata Outline projection");
      Require_Marker (Outline_Tests, "abstract procedure metadata is retained in outline details", "abstract outline detail regression");
      Require_Outline_Test ("Test_Phase579_Declaration_Navigation_Availability_Rejects_Stale_Target", "declaration navigation availability stale-target rejection");
      Require_Marker (Outline_Tests, "old refresh-outline spelling is not a stable command", "canonical Outline command regression");
      Require_Marker (Outline_Tests, "old clear-outline spelling is not a stable command", "canonical Outline command regression");
      Require_Marker (Outline_Tests, "old show-outline spelling is not a stable command", "canonical Outline command regression");
      Require_Marker (Outline_Tests, "old focus-outline spelling is not a stable command", "canonical Outline command regression");
      Require_Marker (Outline_Tests, "old open-selected-outline-item spelling is not a stable command", "canonical Outline command regression");
      Require_Marker ("tests/src/editor-command_surface-tests.adb", "legacy refresh-outline spelling must not resolve", "canonical Outline command surface regression");
   end Check_Test_Coverage;

   procedure Check_Documentation is
   begin
      Forbid_Marker ("docs/outline.md", "not a compiler-grade Ada parser, semantic index, project-wide symbol database", "stale Outline documentation");
      Forbid_Marker ("docs/outline.md", "record representation-clause interpretation beyond safe skipping", "stale representation documentation");
      Forbid_Marker ("docs/outline.md", "complete conditional/generated-source awareness", "stale conditional/generated documentation");
      Forbid_Marker ("docs/syntax_colouring.md", "performs conservative local declaration extraction", "stale semantic documentation");
      Require_Marker ("docs/outline.md", "parser-backed", "current Outline documentation");
      Require_Marker ("docs/outline.md", "statement awareness metadata", "statement awareness documentation");
      Require_Marker ("docs/syntax_colouring.md", "Editor.Ada_Language_Model.Analysis_Result", "current semantic documentation");
      Require_Marker ("docs/syntax_colouring.md", "statement awareness metadata", "statement awareness documentation");
      Require_Marker ("README.md", "phase579_language_validation_check", "release validation documentation");
      Require_Marker ("README.md", "Phase 579 pass735", "pass735 validation guard cleanup documentation");
      Require_Marker ("docs/outline.md", "Phase 579 pass735 validation guard cleanup", "pass735 Outline validation guard note");
      Require_Marker ("docs/syntax_colouring.md", "Phase 579 pass735 validation guard cleanup", "pass735 semantic-colouring validation guard note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass735", "pass735 release checklist guard note");
      Require_File (Tool, "docs/ada_parser_coverage_matrix.md");
      Require_Marker ("README.md", "Phase 579 pass736", "pass736 coverage matrix documentation");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Ada parser coverage matrix", "pass736 coverage matrix title");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Token-cursor coverage", "pass736 matrix token-cursor column");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Syntax-tree / parser coverage", "pass736 matrix parser column");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Language-model projection", "pass736 matrix language-model column");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Resolver / semantic-colouring use", "pass736 matrix resolver-colouring column");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Explicit non-goals", "pass736 matrix non-goals column");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Representation and operational items", "pass736 matrix representation row");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Anonymous access-to-subprogram definitions", "pass736 matrix anonymous access row");
      Require_Marker ("docs/outline.md", "Phase 579 pass736 parser coverage matrix", "pass736 Outline matrix note");
      Require_Marker ("docs/syntax_colouring.md", "Phase 579 pass736 parser coverage matrix", "pass736 semantic-colouring matrix note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass736", "pass736 release checklist matrix note");
      Require_Marker ("README.md", "Phase 579 pass737", "pass737 case statement documentation");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "case-statement alternatives", "pass737 matrix case statement note");
      Require_Marker ("docs/outline.md", "Phase 579 pass737 case-statement alternative depth", "pass737 Outline case statement note");
      Require_Marker ("docs/syntax_colouring.md", "Phase 579 pass737 case-statement alternative depth", "pass737 semantic-colouring case statement note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass737", "pass737 release checklist case statement note");
      Require_Marker ("README.md", "Phase 579 pass738", "pass738 select statement documentation");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "select-statement alternatives", "pass738 matrix select statement note");
      Require_Marker ("docs/outline.md", "Phase 579 pass738 select-statement alternative depth", "pass738 Outline select statement note");
      Require_Marker ("docs/syntax_colouring.md", "Phase 579 pass738 select-statement alternative depth", "pass738 semantic-colouring select statement note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass738", "pass738 release checklist select statement note");
      Require_Marker ("README.md", "Phase 579 pass739", "pass739 exception handler documentation");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "exception-handler choice depth", "pass739 matrix exception handler note");
      Require_Marker ("docs/outline.md", "Phase 579 pass739 exception-handler choice depth", "pass739 Outline exception handler note");
      Require_Marker ("docs/syntax_colouring.md", "Phase 579 pass739 exception-handler choice depth", "pass739 semantic-colouring exception handler note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass739", "pass739 release checklist exception handler note");
      Require_Marker ("README.md", "Phase 579 pass760", "pass760 README coverage matrix refresh note");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Ada parser coverage matrix — Phase 579 pass770", "pass763 coverage matrix title");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Entry/tasking statements", "pass760 matrix entry tasking row");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Separate subunits and body stubs", "pass760 matrix separate subunit row");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "local duplicate representation diagnostics", "pass760 matrix local representation diagnostics note");
      Require_Marker ("docs/outline.md", "Phase 579 pass760 coverage-matrix refresh", "pass760 Outline matrix refresh note");
      Require_Marker ("docs/syntax_colouring.md", "Phase 579 pass760 coverage-matrix refresh", "pass760 semantic-colouring matrix refresh note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass760 release guard", "pass760 release checklist matrix refresh note");
      Require_Marker ("README.md", "Phase 579 pass762", "pass762 README call ambiguity resolver hint note");
      Require_Marker ("docs/syntax_colouring.md", "Phase 579 pass762 call ambiguity resolver hints", "pass762 syntax-colouring docs note");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Call/entry-call resolver hints", "pass762 matrix call ambiguity resolver hint row");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass762 release guard", "pass762 release checklist call ambiguity resolver hint note");
      Require_Marker ("README.md", "Phase 579 pass763", "pass763 README body-stub aspect placement note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass763 release guard", "pass763 release checklist body-stub aspect placement note");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "subprogram/entry/package/task/protected body stubs", "pass763 coverage matrix body-stub aspect placement note");
      Require_Marker ("README.md", "Phase 579 pass764", "pass764 README formal package positional actual note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass764 release guard", "pass764 release checklist formal package positional actual note");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "positional associations, named associations", "pass764 coverage matrix formal package positional actual note");
      Require_Marker ("README.md", "Phase 579 pass769", "pass769 README body declarative recovery note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass769 release guard", "pass769 release checklist body declarative recovery note");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "body declarative recovery boundaries", "pass769 coverage matrix body declarative recovery note");
      Require_Marker ("README.md", "Phase 579 pass770", "pass770 README protected anonymous access profile note");
      Require_Marker ("docs/release/RELEASE_CHECKLIST.md", "Phase 579 pass770 release guard", "pass770 release checklist protected anonymous access profile note");
      Require_Marker ("docs/ada_parser_coverage_matrix.md", "Phase 579 pass770 note", "pass770 coverage matrix protected anonymous access profile note");
      Require_Marker ("docs/commands.md", "`outline.refresh`", "canonical Outline command documentation");
      Require_Marker ("docs/outline.md", "`outline.refresh`", "canonical Outline command documentation");
      Forbid_Marker ("docs/commands.md", "refresh-outline", "legacy Outline command documentation");
      Forbid_Marker ("docs/commands.md", "open-selected-outline-item", "legacy Outline command documentation");
      Forbid_Marker ("docs/outline.md", "refresh-outline", "legacy Outline command documentation");
      Forbid_Marker ("docs/outline.md", "open-selected-outline-item", "legacy Outline command documentation");
   end Check_Documentation;

   Status : Integer;
begin
   Require_File (Tool, Language_Model_Spec);
   Require_File (Tool, Language_Model_Body);
   Require_File (Tool, Parser_Spec);
   Require_File (Tool, Parser_Body);
   Require_File (Tool, Resolver_Spec);
   Require_File (Tool, Resolver_Body);
   Require_File (Tool, Index_Spec);
   Require_File (Tool, Index_Body);
   Require_File (Tool, Outline_Source);
   Require_File (Tool, Semantics_Source);
   Require_File (Tool, "tests/tests.gpr");
   Require_File (Tool, "tests/alire.toml");
   Require_File (Tool, Syntax_Tests);
   Require_File (Tool, Outline_Tests);
   Require_File (Tool, "docs/outline.md");
   Require_File (Tool, "docs/syntax_colouring.md");
   Require_File (Tool, "README.md");
   Require_File (Tool, Validation_Check_Source);

   if not Has ("tests/alire.toml", "aunit") then
      Fail
        (Tool,
         "tests/alire.toml must declare the AUnit dependency used by phase 579 tests");
   end if;

   Check_Architecture;
   Check_Parser_And_Model_Features;
   Check_Resolver_And_Index_Features;
   Check_Test_Coverage;
   Check_Recent_Grammar_Pass_Guards;
   Check_Documentation;

   if not Command_Exists ("gprbuild") then
      if Strict ("EDITOR_REQUIRE_PHASE579_LANGUAGE_VALIDATION") then
         Fail
           (Tool,
            "gprbuild not found; cannot perform required phase 579 GNAT/AUnit validation");
      else
         Info
           (Tool,
            "gprbuild not found; phase 579 GNAT/AUnit validation skipped after static checks");
         return;
      end if;
   end if;

   Info (Tool, "building AUnit suite through tests/tests.gpr");
   Status := Run3 ("gprbuild", "-q", "-P", "tests/tests.gpr");
   if Status /= 0 then
      Fail (Tool, "phase 579 AUnit build failed");
   end if;

   Info (Tool, "running AUnit suite");
   Status := Run0 ("tests/bin/tests");
   if Status /= 0 then
      Fail (Tool, "phase 579 AUnit suite failed");
   end if;

   Info (Tool, "phase 579 GNAT/AUnit validation passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Phase579_Language_Validation_Check;
--  Pass 368 validation guard tokens: Test_Resolver_Generic_Instance_Expression_Inference_Substitutes_Actuals Effective_Inferred_Type_From_Symbol generic instance expression inference substituted actual types
--  Pass 369 validation guard tokens: Navigation_Target_Ambiguous Resolve_Unit_Family_Targets ambiguity-aware IDE navigation UX

--  Pass 370 validation guard tokens: Navigation_Candidate_Display_Label Navigation_Candidate_Detail_Label ambiguity chooser display detail labels

--  Pass 371 validation guard tokens: Representation_Clause_Info Enumeration_Representation_Literal_Info Add_Representation_Clause Add_Enumeration_Representation_Literal Test_Language_Model_Representation_Clauses_Beyond_Record_Layout
--  Pass 373 validation guard: based literal exponent representation expressions are covered by Test_Language_Model_Representation_Based_Exponent_Expressions.
--  Pass 374 guard note: representation static-expression coverage must include
--  prior named-number constants, not only literal arithmetic.
--  Pass 375 validation note: executable-statement semantic bindings are part
--  of the Phase 579 language model completeness surface.

--  Pass 376 guard: executable expression calls must remain parser-owned
--  bindings.  Keep Test_Language_Model_Executable_Expression_Call_Bindings
--  and Add_Call_Targets_In_Expression so conditions, assignment RHS calls,
--  and nested actual calls do not regress to standalone-call-only metadata.

--  Pass 377 validation guard: executable selected component binding coverage
--  should retain Test_Language_Model_Executable_Selected_Component_Uses and
--  Add_Selected_Components_In_Expression.

--  Pass 378 validation note: Binding_Case_Choice and
--  Test_Language_Model_Executable_Case_Choices_Are_Distinct preserve
--  executable case-choice metadata independently of exception handlers.

-- Pass 379 validation note: deep executable expression/name bindings are part of the Phase 579 language model completeness surface.

--  Pass 380 validation note: Binding_Attribute_Prefix preserves executable
--  attribute prefix metadata independently from Binding_Qualified_Expression_Target.
--  Pass 381 guard: executable raise/requeue/accept targets must remain parser-owned bindings.
--  Pass 382 validation note: executable block-label and exit-target bindings
--  are retained as parser-owned metadata through Binding_Block_Label and
--  Binding_Exit_Target.

--  Pass 383 validation note: executable return statement targets and
--  extended-return objects are retained as Binding_Return_Target and
--  Binding_Return_Object metadata.

--  Pass 384 validation note: executable delay/abort targets are retained as
--  Binding_Delay_Target and Binding_Abort_Target metadata.
--  Pass 385 validation note: executable condition/selector and iteration-source
--  metadata is retained as Binding_Condition_Target and Binding_Iteration_Source.
--  Pass 386 validation note: executable select-statement guards and entry-call
--  alternatives are represented by Binding_Select_Guard and
--  Binding_Select_Entry_Call with Test_Language_Model_Executable_Select_Bindings.

--  Pass 387 validation note: executable timed select alternatives must remain
--  represented as Binding_Select_Delay_Target and covered by
--  Test_Language_Model_Executable_Select_Bindings.

--  Pass 388 guard note: select terminate alternatives are retained as
--  Binding_Select_Terminate and covered by
--  Test_Language_Model_Executable_Select_Bindings.

--  Pass 389 guard note: protected entry barriers are represented by
--  Binding_Entry_Barrier and covered by
--  Test_Language_Model_Executable_Entry_Barrier_Bindings.

--  Pass 390 validation note: executable range-bound names are retained as
--  Binding_Range_Bound and covered by
--  Test_Language_Model_Executable_Range_Bound_Bindings.

--  Pass 391 validation note: executable assertion-style pragma arguments are
--  retained as Binding_Pragma_Argument and covered by
--  Test_Language_Model_Executable_Pragma_Argument_Bindings.

--  Pass 392 guard note: keep Binding_Quantified_Parameter, Binding_Quantified_Source,
--  and Test_Language_Model_Executable_Quantified_Expression_Bindings so
--  executable quantified-expression bindings do not regress.

--  Pass 393 guard note: keep Binding_Named_Actual and
--  Test_Language_Model_Executable_Named_Actual_Bindings so call
--  parameter associations stay distinct from aggregate component metadata.

--  Pass 394 guard note: keep Binding_Case_Expression_Selector,
--  Binding_Case_Expression_Choice, and
--  Test_Language_Model_Executable_Case_Expression_Bindings so executable
--  case-expression metadata remains distinct from statement case alternatives.

--  Pass 395 validation note: executable conditional-expression condition and
--  branch names are retained as Binding_Conditional_Expression_Condition and
--  Binding_Conditional_Expression_Branch metadata.

--  Pass 396 validation note: executable raise-expression exception targets are
--  retained as Binding_Raise_Expression_Target metadata, distinct from
--  statement-level Binding_Raise_Target.
--  Pass 398 validation note: executable expression binding coverage includes
--  Binding_Type_Conversion_Target so conversion-shaped expressions with
--  retained type-like prefixes are not conflated with calls or indexing.
--  Pass 399 validation marker: contract/assertion aspects retain Binding_Aspect_Expression rows and nested executable expression metadata.
--  Pass 400 validation note: accept statement formals are retained through
--  Binding_Accept_Parameter as bounded executable semantic metadata.

--  Pass 401 guard: keep Binding_Exception_Occurrence and the
--  regression test for exception occurrence identifiers distinct from
--  exception-handler choices.

--  Pass 402 validation note: filtered-loop expressions are retained through
--  Binding_Iteration_Filter and covered by
--  Test_Language_Model_Executable_Iterator_Filter_Bindings.
--  Pass 403 guard note: asynchronous select abort alternatives are represented
--  as Binding_Select_Abort and covered by Test_Language_Model_Executable_Select_Bindings.
--  Pass 706 guard note: semantic colouring maps parser-owned executable
--  binding roles conservatively: callable/type-like forms get precise fallback
--  buckets, while unresolved selected components and attribute prefixes degrade
--  to ordinary identifiers to avoid false positives.

--  Pass 404 guard: keep Binding_Entry_Family_Index and
--  Test_Language_Model_Executable_Entry_Family_Index_Bindings so
--  entry-family calls do not regress to array-index metadata.

--  Pass410 validation guard: quantified expressions must parse their
--  quantified loop scheme instead of opaque-skipping to =>.  Keep
--  Test_Language_Model_Token_Cursor_Quantified_Expression_Grammar_Completeness
--  covering both for-all/in and for-some/of forms.

--  Pass411 validation guard: Ada 2022 declare expressions must remain parsed
--  as expression primaries rather than block statements.  Keep
--  Test_Language_Model_Token_Cursor_Declare_Expression_Grammar_Completeness
--  and Production_Declare_Expression coverage.

--  Pass412 validation guard: task/protected type headers with discriminants
--  must retain Production_Task_Type_Declaration and
--  Production_Protected_Type_Declaration through
--  Test_Language_Model_Token_Cursor_Task_Protected_Type_Header_Grammar_Completeness.

--  Pass413 validation guard: aggregate iterated component associations must
--  retain Production_Iterated_Component_Association and must not reuse the
--  quantified-expression grammar path, because Ada aggregate iterators use
--  ``for ... in/of ... =>`` without ``all``/``some`` quantifiers.


--  Pass 435 parser-completeness guard: named discriminant constraints must not
--  regress to ordinary array index-constraint recovery.  The token-cursor
--  grammar retains Production_Discriminant_Constraint,
--  Production_Discriminant_Association, and
--  Production_Discriminant_Selector_Name for forms such as
--  Bounds (Low | High => 1), while ordinary array constraints continue
--  to use Production_Index_Constraint.

--  Pass 692 guard: expression-family token-cursor coverage must retain
--  Production_If_Expression_Branch_Expression,
--  Production_Case_Expression_Choice_List, Production_Case_Expression_Arrow,
--  Production_Quantified_Arrow, Production_Parallel_Reduction_Expression, and
--  Production_Map_Reduction_Expression.  Keep
--  Test_Language_Model_Token_Cursor_Expression_Refinement_Grammar_Completeness
--  so nested conditional/case/quantified/allocator/reduction forms recover into
--  following declarations without becoming opaque expression blobs.


--  Pass 693 guard: name-family token-cursor coverage must retain
--  Production_Selected_Name_Prefix, Production_Selected_Literal_Selector,
--  Production_Allocator_Subtype_Mark, Production_Allocator_Access_Subtype,
--  and Production_Qualified_Expression_Apostrophe.  Keep
--  Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness
--  so selected operator/character literal names, qualified-expression
--  apostrophe boundaries, and allocator subtype forms remain structural and
--  recover into following declarations.

--  Pass 698 guard: discriminant grammar depth must retain
--  Production_Known_Discriminant_Part,
--  Production_Discriminant_Null_Exclusion,
--  Production_Discriminant_Access_Definition, and
--  Production_Discriminant_Constraint_Expression.  Keep
--  Test_Language_Model_Token_Cursor_Discriminant_Depth_Grammar_Completeness
--  so known/unknown discriminants, access discriminants, defaults, and named
--  discriminant constraints remain structural and recover into following
--  declarations.


--  Pass 699 guard: variant-record grammar depth must retain
--  Production_Variant_Choice_Arrow, Production_Variant_Others_Choice,
--  Production_Variant_Choice_Separator, Production_Nested_Variant_Part, and
--  Production_Variant_Recovery_Boundary.  Keep
--  Test_Language_Model_Token_Cursor_Variant_Record_Depth_Grammar_Completeness
--  so case discriminants, when alternatives, nested variants, others choices,
--  and malformed variant alternatives remain structural and recover into
--  following declarations.


--  Pass 700 guard: entry/select grammar depth must retain
--  Production_Select_Entry_Call_Alternative,
--  Production_Timed_Entry_Call_Alternative,
--  Production_Conditional_Entry_Call_Alternative,
--  Production_Select_Delay_Alternative, Production_Entry_Call_Entry_Name,
--  and Production_Entry_Call_Index.  Keep
--  Test_Language_Model_Token_Cursor_Entry_Select_Depth_Grammar_Completeness
--  so entry calls, timed entry calls, conditional entry calls, guarded
--  selective alternatives, delay alternatives, terminate alternatives, and
--  recovery into following declarations remain structural.

--  Pass 701 guard note: exception-depth grammar must retain
--  Production_Exception_Renaming_Target, Production_Exception_Handler_Local_Name,
--  Production_Exception_Choice_Arrow, Production_Exception_Others_Choice,
--  Production_Raise_Statement_Target, Production_Raise_Expression_Target,
--  Production_Raise_Expression_Message, and
--  Test_Language_Model_Token_Cursor_Exception_Depth_Grammar_Completeness.


--  Pass 707 guard note: Outline precision for expanded Ada constructs must
--  retain variant-record labels, entry-family labels, and the regression test
--  Test_Phase707_Ada_Outline_Precision_For_Expanded_Constructs.  These are
--  presentation refinements over parser-owned language-model metadata only;
--  they do not imply compiler-grade variant, tasking, generic, separate-body,
--  visibility, overload, or elaboration legality checking.


--  Pass 708 guard note: aggregate association depth must retain
--  Production_Aggregate_Positional_Component,
--  Production_Aggregate_Named_Component_Association,
--  Production_Aggregate_Component_Choice_List,
--  Production_Aggregate_Component_Arrow, Production_Aggregate_Others_Choice,
--  Production_Null_Record_Aggregate, and
--  Production_Aggregate_Recovery_Boundary.  Keep
--  Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness
--  so positional aggregates, named associations, others choices, null-record
--  extension aggregates, and malformed association recovery remain structural
--  without becoming opaque expression blobs.

--  Pass 712 guard note: assignment/call statement ambiguity must retain
--  Production_Statement_Name_Suffix,
--  Production_Assignment_Selected_Target,
--  Production_Assignment_Indexed_Target,
--  Production_Assignment_Slice_Target,
--  Production_Assignment_Dereference_Target,
--  Production_Call_Selected_Target, Production_Call_Actual_Association, and
--  Test_Language_Model_Token_Cursor_Assignment_Call_Ambiguity_Grammar_Completeness.
--  The parser remains structural only; this is not compiler-grade call
--  resolution, assignment target legality, overload resolution, visibility,
--  or expected-type analysis.

--  Pass 723 guard note: subtype-indication grammar depth must retain
--  Production_Subtype_Mark, Production_Subtype_Null_Exclusion,
--  Production_Subtype_Range_Constraint, Production_Subtype_Digits_Constraint,
--  Production_Subtype_Delta_Constraint, Production_Subtype_Index_Constraint,
--  Production_Subtype_Discriminant_Constraint, and
--  Test_Language_Model_Token_Cursor_Subtype_Indication_Depth_Grammar_Completeness.
--  The parser remains structural only; this is not compiler-grade subtype
--  compatibility, staticness, accessibility, dimensionality, discriminant,
--  visibility, or expected-type legality checking.

--  Pass 724-751 validation guard note: recent grammar-depth markers are
--  intentionally centralized in Check_Recent_Grammar_Pass_Guards.  Keep that
--  grouped matrix in pass order so failures identify the affected family:
--  object declarations, number declarations, formal package actuals,
--  use-clause projection, formal package resolver views, pragma placement,
--  aspect placement, representation source forms, package recovery, anonymous
--  access-to-subprogram profiles, expression/name edge recovery, case-statement alternative depth, select-statement alternative depth, exception-handler choice depth, loop iteration-scheme depth, entry-family/index depth, variant-record component depth, and aggregate association depth, profile parameter metadata, generic formal type metadata, and conservative syntax-recovery diagnostics, hostile mixed-source recovery, extended return object qualifiers, abort target lists, raise statement/expression depth, and standalone delay statement depth.  These
--  guards prove parser/model regression coverage only; they do not imply
--  compiler-grade legality checking.


--  Pass 770 guard note: protected anonymous access-to-subprogram depth must
--  retain Production_Access_Protected_Subprogram_Definition,
--  Production_Access_Protected_Procedure_Profile,
--  Production_Access_Protected_Function_Profile, and
--  Test_Language_Model_Token_Cursor_Anonymous_Access_Protected_Profile_Depth.
--  This remains structural grammar metadata only; it is not protected-operation
--  legality, accessibility analysis, profile conformance, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.

--  Pass 771 guard note: semantic-colouring metadata projection must preserve
--  concrete parser-owned symbol kinds over metadata-only fallback roles.  Keep
--  Test_Syntax_Semantics_Metadata_Does_Not_Downgrade_Symbols_Pass771 and the
--  Preserve_Existing path in Editor.Syntax_Semantics.Build_Map_From_Analysis
--  so visibility, pragma, profile, representation, and unresolved executable
--  metadata cannot downgrade a known declaration.  This is projection precision
--  only; it is not compiler-grade visibility, overload, pragma/aspect legality,
--  representation legality, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass 772 guard note: bounded call-association diagnostics must retain
--  Legality_Positional_Call_Actual_After_Named and
--  Test_Language_Model_Legality_Call_Positional_After_Named_Pass772.  The
--  diagnostic is local parser-owned association-list shape checking only; it
--  is not overload resolution, callable profile matching, parameter conformance,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.

--  Pass 773 guard note: selected-name chain depth must retain
--  Production_Selected_Name_Separator,
--  Production_Selected_Name_Chain_Component,
--  Production_Selected_Name_Missing_Selector, and the extended
--  Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness.
--  This is structural parser metadata for selected-name boundaries and
--  dangling-selector recovery only; it is not name resolution, selector
--  legality, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass 774 guard note: allocator constraint metadata must retain
--  Production_Allocator_Null_Exclusion, Production_Allocator_Index_Constraint,
--  Production_Allocator_Discriminant_Constraint, and
--  Test_Language_Model_Token_Cursor_Allocator_Constraint_Depth_Pass774.
--  This remains structural grammar metadata only; it is not allocator
--  accessibility checking, subtype compatibility checking, constraint legality,
--  overload resolution, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass 775 guard note: renaming-specific aspect placement must retain
--  Production_Renaming_Aspect_Specification and
--  Test_Language_Model_Token_Cursor_Renaming_Aspect_Placement_Pass775.
--  This remains structural parser metadata for aspects attached to object,
--  package, and subprogram renaming declarations; it is not renaming legality,
--  renamed-entity resolution, aspect legality, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.


--  Pass 776 guard note: generic formal type edge-depth parsing must retain
--  Production_Formal_Scalar_Box_Recovery_Boundary,
--  Production_Formal_Derived_Interface_List,
--  Production_Formal_Interface_Ancestor_List, and
--  Test_Language_Model_Token_Cursor_Generic_Formal_Type_Edge_Depth_Pass776.
--  This is bounded structural parser metadata only; it is not compiler-grade
--  generic contract conformance, formal matching, static-expression validation,
--  private-extension legality, overload resolution, compiler invocation, LSP
--  integration, render-side parsing, or dirty-state mutation.
--  Pass777 guard markers: Production_Size_Attribute_Definition_Clause,
--  Production_Alignment_Attribute_Definition_Clause,
--  Production_External_Tag_Attribute_Definition_Clause,
--  Production_Storage_Attribute_Definition_Clause,
--  Test_Language_Model_Token_Cursor_Attribute_Definition_Detail_Pass777.


--  Pass778 guard markers: Production_Protected_Procedure_Body,
--  Production_Protected_Function_Body, Production_Protected_Entry_Body,
--  Production_Protected_Entry_Barrier_Condition, and
--  Test_Language_Model_Token_Cursor_Protected_Body_Operation_Depth_Pass778.
--  This remains structural parser metadata only; it is not protected-operation
--  legality, barrier semantics, body/spec conformance, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.

--  Pass781 guard markers: Production_If_Expression_Missing_Else_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_If_Expression_Else_Recovery_Pass781.
--  This is bounded structural recovery for malformed/in-progress Ada if
--  expressions only; it is not compiler-grade conditional-expression legality,
--  expected-type analysis, overload resolution, compiler invocation, LSP
--  integration, render-side parsing, or dirty-state mutation.

--  Pass782 guard markers: Production_Case_Expression_Missing_Arrow_Recovery_Boundary,
--  Production_Case_Expression_Missing_Alternative_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Case_Expression_Recovery_Pass782.
--  This is bounded structural recovery for malformed/in-progress Ada case
--  expressions only; it is not compiler-grade case-expression legality,
--  choice coverage checking, expected-type analysis, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.

--  Pass783 guard markers: Production_Quantified_Missing_Domain_Recovery_Boundary,
--  Production_Quantified_Missing_Arrow_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Quantified_Recovery_Pass783.
--  This is bounded structural recovery for malformed/in-progress Ada
--  quantified expressions only; it is not compiler-grade quantified-expression
--  legality, iterator legality, expected-type analysis, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.


--  Pass789 guard markers: Production_Timed_Entry_Call_Statement,
--  Production_Timed_Entry_Call_Entry_Call_Part,
--  Production_Conditional_Entry_Call_Statement,
--  Production_Conditional_Entry_Call_Entry_Call_Part, and
--  Test_Language_Model_Token_Cursor_Timed_Conditional_Entry_Call_Pass789.
--  This is bounded structural metadata for timed and conditional entry-call
--  select statements only; it is not tasking legality, entry-call resolution,
--  delay legality, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass790 guard markers: Production_Requeue_Terminator,
--  Production_Requeue_With_Missing_Abort_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Requeue_Recovery_Pass790.

--  Pass791 guard markers: Production_Terminate_Terminator,
--  Production_Terminate_Missing_Terminator_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Terminate_Alternative_Recovery_Pass791.

--  Pass792 guard markers: Production_Abort_Terminator,
--  Production_Abort_Missing_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Abort_Terminator_Recovery_Pass792.
--  This is bounded structural metadata for abort statements only; it is not
--  tasking legality, task-name resolution, abortability legality checking,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.


--  Pass793 guard markers: Production_Delay_Statement_Terminator,
--  Production_Delay_Missing_Terminator_Recovery_Boundary, Production_Return_Terminator, Production_Extended_Return_Missing_End_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Delay_Terminator_Recovery_Pass793.
--  This is bounded structural metadata for delay statements only; it is not
--  delay-expression legality, real-time semantics, select-alternative legality,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.

--  Pass802 guard markers: Production_Case_Statement_End_Keyword,
--  Production_Case_End_Terminator,
--  Production_Case_Missing_End_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Case_End_Terminator_Recovery_Pass802.
--  This is bounded structural metadata for case statement endings only; it is
--  not case-choice coverage checking, end-name matching, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.

--  Pass803 guard markers: Production_Case_Alternative_Missing_Arrow_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Case_Alternative_Missing_Arrow_Pass803.
--  This is bounded structural metadata for case statement alternatives only; it is
--  not case-choice coverage checking, duplicate-choice analysis, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.

--  Pass804 guard markers: Production_If_Statement_Missing_Then_Recovery_Boundary,
--  Production_Elsif_Statement_Missing_Then_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_If_Missing_Then_Recovery_Pass804.
--  This is bounded structural metadata for malformed/in-progress if and elsif
--  branches only; it is not condition legality checking, expected Boolean type
--  analysis, control-flow analysis, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass805 guard markers: Production_For_Loop_Missing_Loop_Recovery_Boundary,
--  Production_Iterator_Loop_Missing_Loop_Recovery_Boundary,
--  Production_While_Loop_Missing_Loop_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Loop_Missing_Loop_Recovery_Pass805.
--  This is bounded structural metadata for malformed/in-progress loop headers
--  only; it is not loop legality checking, iterator legality checking,
--  condition legality checking, discrete-range validation, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.

--  Pass806 guard markers: Production_Package_Body_End_Keyword,
--  Production_Package_Body_End_Name, Production_Package_Body_End_Terminator,
--  Production_Package_Body_Missing_End_Terminator_Recovery_Boundary,
--  Production_Subprogram_Body_End_Name, Production_Subprogram_Body_End_Terminator,
--  Production_Subprogram_Body_Missing_End_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Body_End_Terminator_Recovery_Pass806.
--  This is bounded structural metadata for package/subprogram body endings only;
--  it is not body/spec conformance checking, end-name matching, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.

--  Pass807 guard markers: Production_Task_Body_End_Name,
--  Production_Task_Body_End_Terminator,
--  Production_Task_Body_Missing_End_Terminator_Recovery_Boundary,
--  Production_Protected_Body_End_Keyword, Production_Protected_Body_End_Name,
--  Production_Protected_Body_End_Terminator,
--  Production_Protected_Body_Missing_End_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Concurrent_Body_End_Terminator_Recovery_Pass807.
--  This is bounded structural metadata for task/protected body endings only;
--  it is not tasking legality checking, protected-operation conformance checking,
--  body/spec conformance checking, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass808 guard markers: Production_Entry_Terminator,
--  Production_Entry_Missing_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Entry_Declaration_Terminator_Recovery_Pass808.
--  This is bounded structural metadata for entry declaration terminators only;
--  it is not entry-family legality checking, protected/task conformance
--  checking, compiler invocation, LSP integration, render-side parsing, or
--  dirty-state mutation.

--  Pass809 guard markers: Production_Entry_Body_Begin_Keyword,
--  Production_Entry_Body_End_Keyword, Production_Entry_Body_End_Name,
--  Production_Entry_Body_End_Terminator,
--  Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Entry_Body_End_Recovery_Pass809.
--  This is bounded structural metadata for entry body endings only; it is not
--  tasking legality checking, entry/body conformance checking, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.


--  Pass810 guard markers: Production_Subprogram_Declaration_Terminator,
--  Production_Subprogram_Declaration_Missing_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Subprogram_Declaration_Terminator_Pass810.
--  This is bounded structural metadata for subprogram declarations only; it is
--  not body/spec conformance checking, callable resolution, aspect legality
--  checking, compiler invocation, LSP integration, render-side parsing, or
--  dirty-state mutation.

--  Pass811 guard markers: Production_Object_Declaration_Terminator,
--  Production_Object_Declaration_Missing_Terminator_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Object_Declaration_Terminator_Pass811.

--  Pass812 guard markers: Production_Type_Declaration_Terminator,
--  Production_Type_Declaration_Missing_Terminator_Recovery_Boundary,
--  Production_Subtype_Declaration_Terminator,
--  Production_Subtype_Declaration_Missing_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Type_Subtype_Declaration_Terminator_Pass812.
--  This is bounded structural metadata for type/subtype declaration completion
--  only; it is not representation legality checking, subtype compatibility
--  checking, compiler invocation, LSP integration, render-side parsing, or
--  dirty-state mutation.


--  Pass813 guard markers: Production_Package_Declaration_End_Keyword,
--  Production_Package_Declaration_End_Name,
--  Production_Package_Declaration_End_Terminator,
--  Production_Package_Declaration_Missing_End_Terminator_Recovery_Boundary,
--  and Test_Language_Model_Token_Cursor_Package_Declaration_End_Terminator_Pass813.
--  This is bounded structural metadata for package declaration endings only; it
--  is not package/spec conformance checking, end-name matching, visibility
--  analysis, compiler invocation, LSP integration, render-side parsing, or
--  dirty-state mutation.

--  Pass814 guard markers: Production_Formal_Package_Actual_Part_Open_Delimiter,
--  Production_Formal_Package_Actual_Part_Close_Delimiter,
--  Production_Formal_Package_Actual_Association_Separator,
--  Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Formal_Package_Actual_Delimiters_Pass814.
--  This is bounded structural metadata for formal package actual-part delimiters
--  and separators only; it is not generic contract conformance, formal package
--  matching, association legality checking, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass815 guard markers: Production_Exception_Declaration_Terminator,
--  Production_Exception_Declaration_Missing_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Exception_Declaration_Terminator_Pass815.
--  This is bounded structural metadata for ordinary exception declaration
--  completion only; it is not exception renaming legality, aspect legality
--  checking, visibility analysis, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass816 guard markers: Production_Number_Declaration_Terminator,
--  Production_Number_Declaration_Missing_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Number_Declaration_Terminator_Pass816.
--  This is bounded structural metadata for named-number declaration completion
--  only; it is not static-expression evaluation, named-number legality,
--  universal numeric resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass817 guard markers: Production_Generic_Formal_Declaration_Terminator,
--  Production_Generic_Formal_Declaration_Missing_Terminator_Recovery_Boundary,
--  Production_Generic_Formal_Aspect_Specification, and
--  Test_Language_Model_Token_Cursor_Generic_Formal_Declaration_Terminator_Pass817.
--  This is bounded structural metadata for generic formal declaration
--  completion only; it is not generic contract conformance, formal declaration
--  legality checking, compiler invocation, LSP integration, render-side parsing,
--  or dirty-state mutation.


--  Pass818 guard markers: Production_Enumeration_Representation_List_Open_Delimiter,
--  Production_Enumeration_Representation_List_Close_Delimiter,
--  Production_Enumeration_Representation_Association_Separator,
--  Production_Enumeration_Representation_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Enumeration_Representation_Delimiters_Pass818.
--  This is bounded structural metadata for enumeration representation
--  delimiters and separators only; it is not representation legality checking,
--  enum-literal coverage validation, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass819 guard markers: Production_Record_Representation_List_Open_Delimiter,
--  Production_Record_Representation_List_Close_Delimiter,
--  Production_Record_Representation_Component_Separator,
--  Production_Record_Representation_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Record_Representation_Delimiters_Pass819.
--  This is bounded structural metadata for record representation delimiters
--  and component separators only; it is not record layout legality checking,
--  component-position validation, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass820 guard markers: Production_Pragma_Argument_List_Open_Delimiter,
--  Production_Pragma_Argument_List_Close_Delimiter,
--  Production_Pragma_Argument_Association_Separator,
--  Production_Pragma_Argument_List_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Pragma_Argument_Delimiters_Pass820.
--  This is bounded structural metadata for pragma argument-list delimiters
--  and separators only; it is not pragma legality checking, aspect/pragma
--  semantic equivalence, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass821 guard markers: Production_Call_Actual_List_Open_Delimiter,
--  Production_Call_Actual_List_Close_Delimiter,
--  Production_Call_Actual_Association_Separator,
--  Production_Call_Actual_List_Missing_Close_Recovery_Boundary,
--  Production_Entry_Call_Actual_List_Open_Delimiter,
--  Production_Entry_Call_Actual_List_Close_Delimiter,
--  Production_Entry_Call_Actual_Association_Separator,
--  Production_Entry_Call_Actual_List_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Call_Actual_Delimiters_Pass821.
--  This is bounded structural metadata for call and entry-call actual-list
--  delimiters and separators only; it is not overload resolution, callable
--  entity legality checking, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass822 guard markers: Production_Generic_Actual_Part_Open_Delimiter,
--  Production_Generic_Actual_Part_Close_Delimiter,
--  Production_Generic_Actual_Association_Separator,
--  Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters_Pass822.
--  This is bounded structural metadata for generic instantiation actual-part
--  delimiters and separators only; it is not generic contract conformance,
--  overload resolution, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass823 guard markers: Production_Protected_Body_Operation_End_Name,
--  Production_Protected_Body_Operation_End_Terminator,
--  Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary,
--  Is_Nested_Statement_End_Follower, and
--  Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail_Pass823.
--  This is bounded structural metadata for protected operation body end-name
--  and terminator recovery only; it is not protected operation legality
--  checking, compiler invocation, LSP integration, render-side parsing, or
--  dirty-state mutation.


--  Pass824 guard markers: Production_Exception_Choice_Missing_Choice_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice_Pass824.
--  This is bounded structural metadata for exception handler choice-list
--  recovery only; it is not exception-choice legality checking, duplicate-choice
--  validation, compiler invocation, LSP integration, render-side parsing, or
--  dirty-state mutation.


--  Pass825 guard markers: Production_Package_Visible_Declarative_Item_Recovery_Boundary,
--  Production_Package_Private_Declarative_Item_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Pass825.
--  This is bounded structural metadata for visible/private package
--  declarative-item recovery only; it is not declarative-item legality checking,
--  visibility analysis, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass826 guard markers: Production_Parameter_Profile_Open_Delimiter,
--  Production_Parameter_Profile_Close_Delimiter,
--  Production_Parameter_Profile_Separator,
--  Production_Parameter_Profile_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters_Pass826.
--  This is bounded structural metadata for parameter profile delimiters,
--  separators, and missing-close recovery only; it is not parameter-mode
--  legality checking, subtype conformance, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.


--  Pass827 guard markers: Production_Discriminant_Part_Open_Delimiter,
--  Production_Discriminant_Part_Close_Delimiter,
--  Production_Discriminant_Specification_Separator,
--  Production_Discriminant_Part_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters_Pass827.
--  This is bounded structural metadata for known/unknown discriminant part
--  delimiters, separators, and missing-close recovery only; it is not
--  discriminant legality checking, discriminant-conformance validation,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.

--  Pass828 guard markers: Production_Index_Constraint_Open_Delimiter,
--  Production_Index_Constraint_Close_Delimiter,
--  Production_Index_Constraint_Item_Separator,
--  Production_Index_Constraint_Missing_Close_Recovery_Boundary,
--  Production_Discriminant_Constraint_Open_Delimiter,
--  Production_Discriminant_Constraint_Close_Delimiter,
--  Production_Discriminant_Association_Separator,
--  Production_Discriminant_Constraint_Missing_Close_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Constraint_Delimiters_Pass828.


--  Pass829 guard markers: Production_Aggregate_Open_Delimiter,
--  Production_Aggregate_Close_Delimiter,
--  Production_Aggregate_Component_Separator,
--  Production_Aggregate_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Aggregate_Delimiters_Pass829.
--  This is bounded structural metadata for aggregate delimiters, separators,
--  and missing-close recovery only; it is not aggregate legality checking,
--  component-choice validation, overload resolution, compiler invocation, LSP
--  integration, render-side parsing, or dirty-state mutation.


--  Pass830 guard markers: Production_Qualified_Expression_Operand_Open_Delimiter,
--  Production_Qualified_Expression_Operand_Close_Delimiter,
--  Production_Qualified_Expression_Operand_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters_Pass830.
--  This is bounded structural metadata for qualified-expression operand
--  delimiters and missing-close recovery only; it is not type conversion
--  disambiguation, qualified-expression legality checking, overload
--  resolution, compiler invocation, LSP integration, render-side parsing, or
--  dirty-state mutation.
--  Pass831 guard markers: Production_Parenthesized_Expression_Open_Delimiter,
--  Production_Parenthesized_Expression_Close_Delimiter,
--  Production_Parenthesized_Expression_Missing_Close_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters_Pass831.

--  Pass832 guard markers: Production_Discrete_Choice_Separator,
--  Production_Discrete_Choice_Missing_Choice_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators_Pass832.
--  This is bounded structural metadata for discrete choice-list separators and
--  missing-choice recovery only; it is not discrete-choice legality checking,
--  duplicate-choice validation, range static evaluation, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.

--  Pass833 guard markers: Production_Enumeration_Type_Open_Delimiter,
--  Production_Enumeration_Type_Close_Delimiter, Production_Enumeration_Literal_Separator,
--  Production_Enumeration_Type_Missing_Close_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters_Pass833.


--  Pass834 guard markers: Production_Digits_Constraint_Expression,
--  Production_Digits_Constraint_Missing_Expression_Recovery_Boundary,
--  Production_Delta_Constraint_Expression,
--  Production_Delta_Constraint_Missing_Expression_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions_Pass834.
--  This is bounded structural metadata for digits/delta constraint operand
--  expressions and missing-expression recovery only; it is not fixed/floating
--  point legality checking, static expression validation, subtype conformance,
--  overload resolution, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass835 guard markers: Production_Range_Constraint_Range_Separator,
--  Production_Range_Constraint_Missing_Lower_Bound_Recovery_Boundary,
--  Production_Range_Constraint_Missing_Upper_Bound_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Range_Constraint_Bounds_Pass835.
--  This is bounded structural metadata for range constraint bounds, the `..`
--  separator, and missing-bound recovery only; it is not static range
--  validation, subtype legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.


--  Pass836 guard markers: Production_Attribute_Argument_List_Open_Delimiter,
--  Production_Attribute_Argument_List_Close_Delimiter,
--  Production_Attribute_Argument_Association_Separator,
--  Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters_Pass836.
--  This is bounded structural metadata for attribute argument-list delimiters,
--  separators, and missing-close recovery only; it is not attribute legality
--  checking, reduction profile conformance, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.


--  Pass837 guard markers: Production_Membership_Choice_Separator,
--  Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators_Pass837.


--  Pass838 guard markers: Production_Case_Expression_Alternative_Separator,
--  Production_Case_Expression_Missing_Alternative_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators_Pass838.

--  Pass839 guard markers: Production_Declare_Expression_Begin_Keyword,
--  Production_Declare_Expression_Missing_Begin_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Declare_Expression_Begin_Recovery_Pass839.
--  This is bounded structural metadata for Ada 2022 declare-expression begin
--  boundaries and missing-begin recovery only; it is not declare-expression
--  legality checking, declarative-item legality checking, expression type
--  resolution, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass840 guard markers: Production_Quantified_Missing_Quantifier_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Quantified_Missing_Quantifier_Pass840.
--  This is bounded structural metadata for quantified-expression missing
--  quantifier recovery only; it is not quantified-expression legality checking,
--  loop-scheme legality checking, predicate type checking, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.


--  Pass841 guard markers: Production_If_Expression_Missing_Then_Recovery_Boundary,
--  Production_Elsif_Expression_Missing_Then_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery_Pass841.
--  This is bounded structural metadata for if-expression and elsif-expression
--  missing-then recovery only; it is not conditional-expression legality
--  checking, branch type checking, overload resolution, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.

--  Pass842 guard markers: Production_Selected_Name_Missing_Selector_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Selected_Name_Missing_Selector_Recovery_Pass842.

--  Pass843 guard markers: Production_Delta_Aggregate_With_Keyword,
--  Production_Delta_Aggregate_Delta_Keyword,
--  Production_Delta_Aggregate_Association_Separator,
--  Production_Delta_Aggregate_Missing_Association_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Delta_Aggregate_Keyword_Recovery_Pass843.

--  Pass844 guard markers: Production_Extension_Aggregate_With_Keyword,
--  Production_Extension_Aggregate_Component_Separator,
--  Production_Extension_Aggregate_Missing_Association_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Extension_Aggregate_Keyword_Recovery_Pass844.

--  Pass845 guard markers: Production_Null_Record_Aggregate_Null_Keyword,
--  Production_Null_Record_Aggregate_Record_Keyword,
--  Production_Null_Record_Aggregate_Missing_Record_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Null_Record_Aggregate_Keyword_Recovery_Pass845.

--  Pass847 guard markers: Production_Iterated_Component_Missing_Domain_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Iterated_Component_Domain_Recovery_Pass847.
--  This is bounded structural metadata for Ada aggregate iterated component
--  associations whose iteration domain is missing before `when` or `=>`; it
--  must remain parser-owned and must not trigger render-side parsing or dirty
--  state mutation.

--  Pass846 guard markers: Production_Iterated_Component_Association_Arrow,
--  Production_Iterated_Component_Missing_Arrow_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Iterated_Component_Arrow_Recovery_Pass846.
--  This is bounded structural metadata for Ada aggregate iterated component
--  association arrows and missing-arrow recovery only; it is not aggregate
--  legality checking, iterator legality checking, expression type resolution,
--  overload resolution, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.

--  Pass848 guard markers: Production_For_Loop_Missing_Domain_Recovery_Boundary,
--  Production_Iterator_Loop_Missing_Domain_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Loop_Iteration_Domain_Recovery_Pass848.

--  Pass849 guard markers: Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary,
--  Production_Quantified_Iterator_Filter_Missing_Condition_Recovery_Boundary,
--  Production_Iterated_Component_Iterator_Filter_Missing_Condition_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Iterator_Filter_Condition_Recovery_Pass849.
--  This is bounded structural metadata for iterator-filter missing-condition
--  recovery only; it is not iterator filter legality checking, predicate type
--  checking, iterator legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.

--  Pass850 guard markers: Production_Exit_When_Missing_Condition_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Exit_When_Condition_Recovery_Pass850.
--  This is bounded structural metadata for exit-when missing-condition
--  recovery only; it is not loop legality checking, condition type checking,
--  overload resolution, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass851 guard markers: Production_Delay_Until_Missing_Expression_Recovery_Boundary,
--  Production_Delay_Relative_Missing_Expression_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Delay_Expression_Recovery_Pass851.
--  This is bounded structural metadata for delay statement missing-expression
--  recovery only; it is not delay legality checking, time-expression type
--  checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass852 guard markers: Production_Requeue_Missing_Terminator_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery_Pass852.
--  Pass853 guard markers: Production_Accept_Missing_Terminator_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery_Pass853.
--  This is bounded structural metadata for requeue statement missing-terminator
--  recovery only; it is not requeue legality checking, entry-family validation,
--  select/accept context validation, overload resolution, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.

--  Pass854 guard markers: Production_Select_Guard_Missing_Condition_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Select_Guard_Condition_Recovery_Pass854.
--  This is bounded structural metadata for select guard missing-condition
--  recovery only; it is not select-statement legality checking, guard
--  condition type checking, tasking legality checking, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, or dirty-state
--  mutation.

--  Pass855 guard markers: Production_Abort_Missing_Target_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Abort_Target_Recovery_Pass855.
--  This is bounded structural metadata for abort statement missing-target
--  recovery only; it is not abort statement legality checking, task-name
--  resolution, tasking legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.

--  Pass856 guard markers: Production_Return_Missing_Terminator_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Pass856.
--  This is bounded structural metadata for return statement missing-terminator
--  recovery only; it is not return-statement legality checking, return type
--  conformance, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass857 guard markers: Production_Raise_Expression_Message_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Raise_Expression_Message_Recovery_Pass857.
--  This is bounded structural metadata for raise-expression missing-message
--  recovery only; it is not raise-expression legality checking, exception
--  visibility analysis, message type checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.

--  Pass858 guard markers: Production_Raise_Statement_Message_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Raise_Statement_Message_Recovery_Pass858.
--  This is bounded structural metadata for raise-statement missing-message
--  recovery only; it is not raise-statement legality checking, exception
--  visibility analysis, message type checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, or dirty-state mutation.

--  Pass859 guard markers: Production_Label_Missing_Close_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Label_Missing_Close_Recovery_Pass859.
--  This is bounded structural metadata for label missing-close recovery only;
--  it is not label legality checking, goto-target resolution, duplicate-label
--  validation, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass860 guard markers: Production_Assignment_Missing_Expression_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Assignment_Expression_Recovery_Pass860.
--  Assignment expression recovery remains parser-owned structural metadata only.

--  Pass861 guard markers: Production_Goto_Missing_Target_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Goto_Target_Recovery_Pass861.
--  Goto target recovery remains parser-owned structural metadata only; it is not
--  label resolution, goto legality checking, compiler invocation, LSP
--  integration, render-side parsing, or dirty-state mutation.

--  Pass862 guard markers: Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Raise_Statement_Exception_Name_Recovery_Pass862.
--  Raise-statement missing exception-name recovery remains parser-owned structural
--  metadata only; it is not raise-statement legality checking, exception
--  visibility analysis, message type checking, compiler invocation, LSP
--  integration, render-side parsing, or dirty-state mutation.


--  Pass863 guard markers: Production_Accept_Missing_Entry_Name_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Accept_Entry_Name_Recovery_Pass863.
--  Accept missing entry-name recovery remains parser-owned structural metadata
--  only; it is not accept statement legality checking, entry profile
--  conformance, tasking legality checking, compiler invocation, LSP
--  integration, render-side parsing, or dirty-state mutation.


--  Pass864 guard markers: Production_Requeue_Missing_Target_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Requeue_Target_Recovery_Pass864.
--  Requeue missing-target recovery remains parser-owned structural metadata only;
--  it is not requeue legality checking, entry-family validation, select/accept
--  context validation, compiler invocation, LSP integration, render-side parsing,
--  or dirty-state mutation.


--  Pass865 guard markers: Production_Extended_Return_Missing_Do_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Extended_Return_Do_Recovery_Pass865.
--  Extended return missing-do recovery remains parser-owned structural metadata
--  only; it is not return-object legality checking, subtype conformance,
--  expression type checking, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass866 guard markers: Production_Case_Statement_Missing_Is_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Case_Statement_Is_Recovery_Pass866.
--  Case statement missing-is recovery remains parser-owned structural metadata
--  only; it is not case-choice coverage checking, discrete-choice legality
--  checking, expression type checking, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass867 guard markers: Production_Case_Choice_Missing_Choice_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery_Pass867.
--  Case choice missing-choice recovery remains parser-owned structural metadata
--  only; it is not case-choice coverage checking, discrete-choice legality
--  checking, static range evaluation, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass868 guard markers: Production_Case_Alternative_Missing_Statement_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Case_Alternative_Statement_Recovery_Pass868.
--  Case alternative missing-statement recovery remains parser-owned structural
--  metadata only; it is not case-choice coverage checking, statement legality
--  checking, control-flow validation, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass869 guard markers: Production_If_Then_Missing_Statement_Recovery_Boundary,
--  Production_Elsif_Missing_Statement_Recovery_Boundary,
--  Production_Else_Missing_Statement_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_If_Branch_Statement_Recovery_Pass869.
--  If branch missing-statement recovery remains parser-owned structural metadata
--  only; it is not statement legality checking, control-flow validation,
--  expression type checking, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.
--  Pass870 guard markers: Production_Loop_Missing_Statement_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Loop_Body_Statement_Recovery_Pass870.

--  Pass871 guard markers: Production_Block_Missing_Statement_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Block_Body_Statement_Recovery_Pass871.
--  Block statement-sequence missing-statement recovery remains parser-owned
--  structural metadata only; it is not statement legality checking, exception
--  handler legality checking, control-flow validation, compiler invocation, LSP
--  integration, render-side parsing, or dirty-state mutation.

--  Pass872 guard markers: Production_Case_Alternative_End_Case_Statement_Recovery_Boundary, Test_Language_Model_Token_Cursor_Case_Alternative_End_Case_Statement_Recovery_Pass872

--  Pass873 guard markers: Production_Formal_Package_Actual_Empty_Recovery_Boundary, Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery_Pass873
--  Empty formal package actual recovery remains parser-owned structural metadata
--  only; it is not generic contract legality checking, actual/default legality
--  checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.

--  Pass874 guard markers: Production_Exception_Handler_Missing_Statement_Recovery_Boundary, Production_Exception_Handler_End_Statement_Recovery_Boundary, Test_Language_Model_Token_Cursor_Exception_Handler_Statement_Recovery_Pass874
--  Pass875 guard markers: Production_Use_Clause_Missing_Name_Recovery_Boundary, Production_Use_Clause_Trailing_Separator_Recovery_Boundary, Production_Use_Clause_Missing_Terminator_Recovery_Boundary, Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery_Pass875
--  Pass876 guard markers: Production_Enumeration_Representation_Empty_List_Recovery_Boundary, Production_Enumeration_Representation_Trailing_Separator_Recovery_Boundary, Production_Enumeration_Representation_Missing_Value_Recovery_Boundary, Test_Language_Model_Token_Cursor_Enumeration_Representation_Recovery_Pass876
--  Exception-handler statement-sequence recovery remains parser-owned structural
--  metadata only; it is not exception choice legality checking, handler ordering
--  validation, statement legality checking, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass877 guard markers: Production_Subprogram_Declaration_Aspect_Specification,
--  Production_Subprogram_Body_Aspect_Specification,
--  Production_Subprogram_Contract_Aspect_Placement, and
--  Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Pass877.
--  Subprogram contract/aspect placement remains parser-owned structural
--  metadata only; it is not contract legality checking, Global/Depends
--  validation, profile conformance, overload resolution, compiler invocation,
--  LSP integration, render-side parsing, or dirty-state mutation.


--  Pass878 guard markers: Production_Package_Nested_Declarative_Item_Recovery_Boundary,
--  Production_Package_Declarative_Private_Boundary,
--  Production_Package_Declarative_Begin_Boundary,
--  Production_Package_Declarative_End_Boundary, and
--  Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Pass878.
--  Package declarative-item recovery remains parser-owned structural metadata
--  only; it is not package legality checking, nested declaration legality
--  checking, visibility checking, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass879 guard markers: Production_Access_Protected_Missing_Subprogram_Recovery_Boundary,
--  Production_Access_Function_Missing_Return_Recovery_Boundary,
--  Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary, Production_Access_Object_Missing_Subtype_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refined_Recovery_Pass879.
--  Anonymous access-to-subprogram recovery remains parser-owned structural
--  metadata only; it is not callable-profile legality checking, result subtype
--  legality checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass880 guard markers: Production_If_Expression_Missing_Condition_Recovery_Boundary,
--  Production_If_Expression_Missing_Then_Branch_Recovery_Boundary,
--  Production_If_Expression_Missing_Else_Branch_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Conditional_Expression_Recovery_Pass880.
--  Conditional-expression operand recovery remains parser-owned structural
--  metadata only; it is not expression type checking, Boolean legality
--  checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.


--  Pass881 guard markers: Production_Qualified_Expression_Selected_Literal_Subtype_Mark,
--  Production_Qualified_Expression_Selected_Operator_Subtype_Mark,
--  Production_Qualified_Expression_Selected_Character_Subtype_Mark,
--  Production_Allocator_Selected_Operator_Subtype_Mark, and
--  Test_Language_Model_Token_Cursor_Selected_Literal_Name_Refinement_Pass881.
--  Selected literal name refinement remains parser-owned structural metadata
--  only; it is not subtype legality checking, operator legality checking,
--  overload resolution, compiler invocation, LSP integration, render-side
--  parsing, or dirty-state mutation.


--  Pass882 guard markers: Production_Select_Alternative_Missing_Statement_Recovery_Boundary,
--  Production_Select_Else_Missing_Statement_Recovery_Boundary,
--  Production_Select_Abortable_Missing_Statement_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Select_Alternative_Statement_Recovery_Pass882.
--  Select-statement alternative statement-sequence recovery remains
--  parser-owned structural metadata only; it is not tasking legality checking,
--  selective-accept legality checking, compiler invocation, LSP integration,
--  render-side parsing, or dirty-state mutation.
--  Pass883 guard markers: Production_Accept_Body_Missing_Statement_Recovery_Boundary,
--  Production_Accept_Body_End_Statement_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Accept_Body_Statement_Recovery_Pass883.

--  Pass884 guard markers: Production_Formal_Incomplete_Type_Declaration,
--  Production_Formal_Incomplete_Tagged_Type_Definition,
--  Production_Formal_Incomplete_Type_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Generic_Formal_Incomplete_Type_Pass884.

--  Pass885 guard markers: Production_Pragma_Identifier_Missing_Recovery_Boundary,
--  Production_Pragma_Argument_List_Empty_Recovery_Boundary,
--  Production_Pragma_Argument_Trailing_Separator_Recovery_Boundary,
--  Production_Pragma_Argument_Missing_Expression_Recovery_Boundary,
--  Production_Pragma_Missing_Terminator_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Pragma_Recovery_Depth_Pass885.
--  Pragma recovery remains parser-owned structural metadata only; it is not
--  pragma legality checking, implementation-defined pragma validation,
--  overload resolution, compiler invocation, LSP integration, render-side
--  parsing, background whole-project scanning, or dirty-state mutation.


--  Pass886 guard markers: Production_Attribute_Definition_Missing_Use_Recovery_Boundary,
--  Production_Attribute_Definition_Missing_Value_Recovery_Boundary,
--  Production_Address_Clause_Missing_Value_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Attribute_Address_Clause_Recovery_Pass886.
--  Attribute/address representation-clause recovery remains parser-owned
--  structural metadata only; it is not representation legality checking,
--  static expression validation, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass887 guard markers: Production_Package_Declaration_Aspect_Specification,
--  Production_Package_Body_Aspect_Specification,
--  Production_Task_Declaration_Aspect_Specification,
--  Production_Task_Body_Aspect_Specification,
--  Production_Protected_Declaration_Aspect_Specification,
--  Production_Protected_Body_Aspect_Specification,
--  Production_Private_Type_Aspect_Specification,
--  Production_Generic_Declaration_Aspect_Specification, and
--  Test_Language_Model_Token_Cursor_Aspect_Placement_Breadth_Pass887.
--  Broader aspect placement remains parser-owned structural metadata only; it
--  is not aspect legality checking, representation aspect validation,
--  contract legality checking, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass888 guard markers: Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Recovery_Pass888.
--  Case-expression dependent-expression recovery remains parser-owned structural
--  metadata only; it is not expression type checking, discrete-choice legality
--  checking, case coverage checking, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass889 guard markers: Production_Attribute_Selected_Prefix,
--  Production_Attribute_Complex_Prefix,
--  Production_Qualified_Expression_Incomplete_Selected_Subtype_Mark,
--  Production_Allocator_Incomplete_Selected_Subtype_Mark, and
--  Test_Language_Model_Token_Cursor_Name_Attribute_Refinement_Pass889.
--  Name/attribute refinement remains parser-owned structural metadata only; it
--  is not attribute legality checking, subtype legality checking, overload
--  resolution, compiler invocation, LSP integration, render-side parsing,
--  background whole-project scanning, or dirty-state mutation.

--  Pass890 guard markers: Production_Task_Body_Declarative_Item_Recovery_Boundary,
--  Production_Task_Body_Declarative_Begin_Boundary,
--  Production_Protected_Body_Declarative_Item_Recovery_Boundary,
--  Production_Protected_Body_Declarative_Begin_Boundary,
--  Test_Language_Model_Token_Cursor_Task_Protected_Body_Declarative_Recovery_Pass890.

--  Pass891 guard markers: Test_Syntax_Semantics_Recovered_Metadata_Suppressed_Pass891,
--  Is_Recovered_Partial_Name, Is_Recovered_Unresolved_Binding.
--  Semantic-colouring metadata consumers must suppress unresolved recovered
--  partial names from incomplete selected subtype marks and recovered visibility
--  names.  Resolved target symbols must still retain concrete semantic kinds.
--  This remains parser-owned/snapshot-owned semantic-colouring follow-through;
--  it is not compiler-grade name binding, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass892 guard markers: Production_Reduction_Missing_Reducer_Recovery_Boundary,
--  Production_Reduction_Missing_Initial_Value_Recovery_Boundary,
--  Production_Reduction_Trailing_Separator_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Reduction_Argument_Recovery_Pass892.
--  Reduction attribute argument recovery remains parser-owned structural
--  metadata only; it is not callable conformance checking, initial-value type
--  compatibility checking, parallel-reduction legality checking, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass893 guard markers: Production_Quantified_Missing_Predicate_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Quantified_Predicate_Recovery_Pass893.
--  Quantified-expression predicate recovery remains parser-owned structural
--  metadata only; it is not Boolean predicate legality checking, iterator
--  legality checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass894 guard markers: Production_Declare_Expression_Missing_Body_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Declare_Expression_Body_Recovery_Pass894.
--  Declare-expression missing-body recovery remains parser-owned structural
--  metadata only; it is not declaration legality checking, body expression type
--  checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass895 guard markers: Production_Iterated_Component_Missing_Expression_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Iterated_Component_Expression_Recovery_Pass895.
--  Iterated component association missing-expression recovery remains
--  parser-owned structural metadata only; it is not aggregate legality
--  checking, iterator legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass896 guard markers: Production_Generic_Actual_Missing_Actual_Recovery_Boundary,
--  Production_Generic_Actual_Trailing_Separator_Recovery_Boundary,
--  Production_Generic_Actual_Empty_List_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Generic_Actual_Association_Recovery_Pass896.
--  Pass897 guard markers: Production_Renaming_Missing_Target_Recovery_Boundary,
--  Production_Renaming_Missing_Renames_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Renaming_Target_Recovery_Pass897.
--  Renaming target recovery remains parser-owned structural metadata only; it
--  is not renamed entity legality checking, visibility checking, overload
--  resolution, compiler invocation, LSP integration, render-side parsing,
--  background whole-project scanning, or dirty-state mutation.

--  Pass898 guard markers: Production_Entry_Body_Statement_Sequence,
--  Production_Entry_Body_Missing_Statement_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Entry_Body_Statement_Recovery_Pass898.
--  Entry-body statement-sequence recovery remains parser-owned structural
--  metadata only; it is not tasking legality checking, entry barrier legality
--  checking, statement legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass899 guard markers: Production_Entry_Barrier_Missing_Condition_Recovery_Boundary,
--  Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Recovery_Pass899.
--  Entry-barrier missing-condition recovery remains parser-owned structural
--  metadata only; it is not tasking legality checking, barrier condition type
--  checking, protected entry legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass900 guard markers: Production_Entry_Family_Empty_Definition_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Entry_Family_Empty_Definition_Recovery_Pass900.
--  Empty entry-family definition recovery remains parser-owned structural
--  metadata only; it is not entry-family legality checking, discrete subtype
--  validation, tasking legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass901 guard markers: Production_Abort_Target_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Abort_Target_Reserved_Boundary_Recovery_Pass901.

--  Pass902 guard markers: Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Requeue_Target_Reserved_Boundary_Recovery_Pass902.
--  Requeue target reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not entry-name legality checking, tasking legality
--  checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass903 guard markers: Production_Delay_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Delay_Expression_Reserved_Boundary_Recovery_Pass903.

--  Pass904 guard markers: Production_Goto_Target_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Goto_Target_Reserved_Boundary_Recovery_Pass904.
--  Goto target reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not label legality checking, control-flow legality
--  checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass905 guard markers: Production_Return_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Return_Expression_Reserved_Boundary_Recovery_Pass905.

--  Pass906 guard markers: Production_Raise_Target_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Raise_Target_Reserved_Boundary_Recovery_Pass906.
--  Raise target reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not exception-name legality checking, exception
--  propagation legality checking, overload resolution, compiler invocation,
--  LSP integration, render-side parsing, background whole-project scanning,
--  or dirty-state mutation.

--  Pass907 guard markers: Production_Exit_Target_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Exit_Target_Reserved_Boundary_Recovery_Pass907.
--  Exit target reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not loop-name legality checking, exit-statement
--  legality checking, overload resolution, compiler invocation, LSP
--  integration, render-side parsing, background whole-project scanning, or
--  dirty-state mutation.

--  Pass908 guard markers: Production_Assignment_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Assignment_Expression_Reserved_Boundary_Recovery_Pass908.

--  Pass909 guard markers: Production_Call_Actual_Missing_Actual_Recovery_Boundary,
--  Production_Call_Actual_Trailing_Separator_Recovery_Boundary,
--  Production_Call_Actual_Empty_List_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Call_Actual_Association_Recovery_Pass909.
--  Call actual association recovery remains parser-owned structural metadata
--  only; it is not callable profile checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass910 guard markers: Production_If_Statement_Missing_Condition_Recovery_Boundary,
--  Production_Elsif_Statement_Missing_Condition_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_If_Elsif_Condition_Recovery_Pass910.
--  If/elsif missing-condition recovery remains parser-owned structural
--  metadata only; it is not Boolean condition legality checking, expression
--  type checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state
--  mutation.

--  Pass911 guard markers: Production_While_Loop_Missing_Condition_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_While_Condition_Recovery_Pass911.
--  While-loop missing-condition recovery remains parser-owned structural
--  metadata only; it is not Boolean condition legality checking, expression
--  type checking, loop-statement legality checking, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, background
--  whole-project scanning, or dirty-state mutation.

--  Pass912 guard markers: Production_For_Loop_Domain_Reserved_Boundary_Recovery_Boundary,
--  Production_Iterator_Loop_Domain_Reserved_Boundary_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_For_Iterator_Domain_Reserved_Boundary_Recovery_Pass912.
--  For/iterator loop domain reserved-boundary recovery remains parser-owned
--  structural metadata only; it is not discrete range legality checking,
--  iterator legality checking, expression type checking, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, background
--  whole-project scanning, or dirty-state mutation.

--  Pass913 guard markers: Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Case_Selector_Reserved_Boundary_Recovery_Pass913.
--  Case-statement selector reserved-boundary recovery remains parser-owned
--  structural metadata only; it is not selector expression legality checking,
--  discrete choice legality checking, case coverage checking, overload
--  resolution, compiler invocation, LSP integration, render-side parsing,
--  background whole-project scanning, or dirty-state mutation.

--  Pass914 guard markers: Production_Extended_Return_Initializer_Reserved_Boundary_Recovery_Boundary
--  Pass914 guard markers: Test_Language_Model_Token_Cursor_Extended_Return_Initializer_Reserved_Boundary_Recovery_Pass914

--  Pass915 guard markers: Production_Raise_Message_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Raise_Message_Reserved_Boundary_Recovery_Pass915.
--  Raise-with-message reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not message-expression legality checking, exception-name
--  legality checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state mutation.

--  Pass916 guard markers: Production_Exit_When_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Exit_When_Reserved_Boundary_Recovery_Pass916.
--  Exit-when condition reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not Boolean condition legality checking, loop-name
--  legality checking, exit-statement legality checking, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, background
--  whole-project scanning, or dirty-state mutation.

--  Pass917 guard markers: Production_Null_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Null_Reserved_Boundary_Recovery_Pass917.

--  Pass918 guard markers: Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Aggregate_Component_Reserved_Boundary_Recovery_Pass918.
--  Aggregate component expression reserved-boundary recovery remains parser-owned
--  structural metadata only; it is not aggregate legality checking, component
--  type checking, overload resolution, compiler invocation, LSP integration,
--  render-side parsing, background whole-project scanning, or dirty-state mutation.

--  Pass919 guard markers: Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Object_Initialization_Reserved_Boundary_Recovery_Pass919.
--  Object-initialization reserved-boundary recovery remains parser-owned
--  structural metadata only; it is not object declaration legality checking,
--  initializer type checking, aspect legality checking, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, background
--  whole-project scanning, or dirty-state mutation.

--  Pass920 guard markers: Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Range_Constraint_Reserved_Boundary_Recovery_Pass920.
--  Range-constraint reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not range-expression legality checking, subtype legality
--  checking, static expression validation, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass921 guard markers: Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary,
--  Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Digits_Delta_Reserved_Boundary_Recovery_Pass921.
--  Digits/delta constraint reserved-boundary recovery remains parser-owned
--  structural metadata only; it is not floating/fixed-point subtype legality
--  checking, static expression validation, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass922 guard markers: Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary,
--  Production_Discriminant_Constraint_Reserved_Boundary_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Index_Discriminant_Constraint_Reserved_Boundary_Recovery_Pass922.
--  Index/discriminant constraint reserved-boundary recovery remains parser-owned
--  structural metadata only; it is not constraint legality checking, subtype
--  compatibility checking, static expression validation, overload resolution,
--  compiler invocation, LSP integration, render-side parsing, background
--  whole-project scanning, or dirty-state mutation.

--  Pass923 guard markers: Production_Profile_Default_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Profile_Default_Reserved_Boundary_Recovery_Pass923.
--  Profile default reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not default-expression legality checking, profile
--  conformance checking, overload resolution, compiler invocation, LSP
--  integration, render-side parsing, background whole-project scanning, or
--  dirty-state mutation.
--  Pass924 guard markers: Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Object_Subtype_Reserved_Boundary_Recovery_Pass924.
--  Object subtype reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not object declaration legality checking, subtype
--  legality checking, aspect legality checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass925 guard markers: Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Number_Initialization_Reserved_Boundary_Recovery_Pass925.
--  Number initialization reserved-boundary recovery remains parser-owned
--  structural metadata only; it is not named-number legality checking,
--  static-expression validation, universal type resolution, overload
--  resolution, compiler invocation, LSP integration, render-side parsing,
--  background whole-project scanning, or dirty-state mutation.
--  Pass926 guard markers: Production_Component_Default_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Component_Default_Reserved_Boundary_Recovery_Pass926.
--  Pass927 guard markers: Production_Discriminant_Default_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Discriminant_Default_Reserved_Boundary_Recovery_Pass927.
--  Pass928 guard markers: Production_Array_Index_Reserved_Boundary_Recovery_Boundary
--  and Test_Language_Model_Token_Cursor_Array_Index_Reserved_Boundary_Recovery_Pass928.
--  Array index reserved-boundary recovery remains parser-owned structural
--  metadata only; it is not array index subtype legality checking, range
--  expression type checking, overload resolution, compiler invocation, LSP
--  integration, render-side parsing, background whole-project scanning, or
--  dirty-state mutation.

--  Pass930 guard markers: Production_Access_Mode_Missing_Subtype_Recovery_Boundary,
--  Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary,
--  Production_Access_Protected_Missing_Subprogram_Boundary_Token,
--  Production_Access_Result_Missing_Subtype_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth_Pass930.
--  Access-definition recovery depth remains parser-owned structural metadata
--  only; it is not access-type legality checking, designated-subtype legality
--  checking, profile conformance checking, overload resolution, compiler
--  invocation, LSP integration, render-side parsing, background whole-project
--  scanning, or dirty-state mutation.

--  Pass931 guard markers: Production_Formal_Subprogram_Default_Abstract_Name,
--  Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery_Pass931.
--  Generic formal subprogram default recovery remains parser-owned structural
--  metadata only; it is not compiler-grade generic contract checking,
--  overload resolution, default conformance checking, compiler invocation,
--  LSP integration, render-side parsing, background whole-project scanning,
--  or dirty-state mutation.

--  Pass933 guard markers: Production_Use_All_Missing_Type_Recovery_Boundary,
--  Production_Use_Clause_Reserved_Name_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Depth_Pass933.
--  Use-clause recovery depth remains parser-owned structural metadata only;
--  it is not compiler-grade visibility legality checking, subtype-mark
--  legality checking, overload resolution, compiler invocation, LSP
--  integration, render-side parsing, background whole-project scanning, or
--  dirty-state mutation.

--  Pass934 guard markers: Production_Representation_Target_Reserved_Boundary_Recovery_Boundary,
--  Production_Representation_Clause_Missing_Use_Recovery_Boundary,
--  Production_Attribute_Definition_Missing_Designator_Recovery_Boundary,
--  Production_Enumeration_Representation_Reserved_Association_Recovery_Boundary,
--  and Test_Language_Model_Token_Cursor_Representation_Item_Recovery_Depth_Pass934.
--  Representation/operational item recovery depth remains parser-owned
--  structural metadata only; it is not compiler-grade representation legality
--  checking, freezing-rule checking, layout validation, static-expression
--  validation, compiler invocation, LSP integration, render-side parsing,
--  background whole-project scanning, or dirty-state mutation.
--  Pass939 guard markers: Production_If_Expression_Condition_Reserved_Boundary,
--  Production_Case_Expression_Missing_Selector_Recovery_Boundary,
--  Production_Case_Expression_Missing_Is_Recovery_Boundary,
--  Production_Parallel_Reduction_Argument_Recovery_Boundary,
--  Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth_Pass939.

--  Pass940 guard markers: Production_Selected_Name_Reserved_Selector_Recovery_Boundary,
--  Production_Allocator_Missing_Subtype_Recovery_Boundary,
--  Production_Qualified_Expression_Missing_Operand_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Name_Grammar_Recovery_Depth_Pass940.
--  Name grammar recovery depth remains parser-owned structural metadata only;
--  it is not compiler-grade selected-name legality checking, allocator subtype
--  legality checking, qualified-expression operand legality checking, overload
--  resolution, compiler invocation, LSP integration, render-side parsing,
--  background whole-project scanning, or dirty-state mutation.

--  Pass941 guard markers: Production_Entry_Body_Missing_Barrier_Recovery_Boundary,
--  Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary, and
--  Test_Language_Model_Token_Cursor_Entry_Body_Missing_Barrier_Recovery_Pass941.
--  Protected entry-body barrier recovery remains parser-owned structural
--  metadata only; it is not compiler-grade tasking legality checking,
--  protected-operation conformance checking, barrier expression legality
--  checking, compiler invocation, LSP integration, render-side parsing,
--  background whole-project scanning, or dirty-state mutation.

--  Pass942 guard markers: Node_Declare_Expression, Node_Delta_Aggregate,
--  Node_Container_Aggregate, Node_Reduction_Expression, Node_Target_Name, and
--  Test_Ada_Syntax_Tree_Ada2022_Expression_Node_Coverage_Pass942.

--  Pass943 guard markers: Editor.Ada_Declarative_Regions, Region_Compilation,
--  Region_Generic_Formal_Part, Region_Package_Spec, Region_Package_Body,
--  Region_Subprogram_Body, Region_Protected_Body, Region_Entry_Body,
--  Test_Ada_Declarative_Region_Model_Foundation_Pass943.

--  PASS944_LANGUAGE_GUARD: Direct visibility foundation is covered by
--  Editor.Ada_Direct_Visibility and
--  Test_Ada_Direct_Visibility_Foundation_Pass944.

--  PASS945_LANGUAGE_GUARD: Use-clause visibility foundation is covered by
--  Editor.Ada_Use_Visibility and
--  Test_Ada_Use_Visibility_Foundation_Pass945.
--  The model is snapshot/tree-owned and must not introduce compiler, LSP,
--  renderer-side parsing, dirty-state mutation, or background scan coupling.

--  Pass946 guard: selected-name resolution foundation must remain parser-owned,
--  deterministic, snapshot-derived, and free of renderer-side parsing, file
--  reloads, dirty-state mutation, compiler invocation, LSP integration, external
--  parser generators, Python, and shell-script project hooks.

--  Pass947 guard: use-type primitive visibility foundation is covered by
--  Editor.Ada_Use_Type_Operators and
--  Test_Ada_Use_Type_Operator_Visibility_Foundation_Pass947.
--  The model remains deterministic and snapshot-owned and must not introduce
--  renderer-side parsing, dirty-state mutation, compiler invocation, LSP
--  integration, external parser generators, Python, or shell-script project
--  hooks.  It is a compiler-grade semantic building block, not yet full
--  overload resolution or type legality.

--  Pass948 guard: call-candidate overload foundation is covered by
--  Editor.Ada_Call_Candidates and
--  Test_Ada_Call_Candidate_Foundation_Pass948.  This remains a deterministic
--  compiler-grade semantic building block before expected-type/profile
--  filtering; it must not introduce compiler invocation, LSP, renderer-side
--  parsing, file IO, background scans, or dirty-state mutation.
--  Pass949 guard marker: Editor.Ada_Call_Profile_Shapes and
--  Test_Ada_Call_Profile_Shape_Foundation_Pass949 must remain present as the
--  call-profile shape foundation for later overload filtering.
--  Pass950 guard marker: Editor.Ada_Call_Profile_Filters and
--  Test_Ada_Call_Profile_Filter_Foundation_Pass950 must remain present as the
--  call-profile arity and named-actual filtering foundation for overload resolution.
--  Pass951 guard marker: Editor.Ada_Call_Profile_Shapes and
--  Editor.Ada_Call_Profile_Filters must retain formal-name/default metadata,
--  and Test_Ada_Call_Profile_Formal_Name_Filter_Pass951 must remain registered
--  as the AUnit coverage marker for matched named actuals, unknown named
--  actuals, and missing required non-defaulted formals.
--  Pass952 guard marker: Editor.Ada_Call_Resolution and
--  Test_Ada_Call_Resolution_Profile_Result_Pass952 must remain present as the
--  call-resolution result classification layer over call candidates and profile
--  filters.  It must remain deterministic and snapshot-owned, with no compiler
--  invocation, LSP integration, renderer-side parsing, file IO, background
--  scans, or dirty-state mutation.
--  Pass954 guard marker: Editor.Ada_Expected_Call_Filters and
--  Test_Ada_Expected_Call_Filter_Foundation_Pass954 must remain present as the
--  expected-call result-subtype filtering layer over expected contexts,
--  call-resolution results, profile filters, and callable profile shapes.  It
--  must remain deterministic and snapshot-owned, with no compiler invocation,
--  LSP integration, renderer-side parsing, file IO, background scans, or
--  dirty-state mutation.

--  Pass955 guard marker: Editor.Ada_Subtype_Compatibility and
--  Test_Ada_Subtype_Compatibility_Foundation_Pass955 must remain present as the
--  conservative subtype-compatibility foundation for expected-call filtering.
--  The model must stay snapshot-owned and must not introduce compiler
--  invocation, LSP integration, renderer-side parsing, background scans, file
--  mutation, or dirty-state mutation.

--  Pass956 guard marker: Editor.Ada_Type_Graph and
--  Test_Ada_Type_Graph_Foundation_Pass956 must remain present as the
--  declaration-derived type graph foundation.  The model must stay
--  parser/snapshot-owned and must not introduce compiler invocation, LSP
--  integration, renderer-side parsing, background scans, file mutation, or
--  dirty-state mutation.

--  Pass957 guard marker: Editor.Ada_Subtype_Compatibility.Check_With_Type_Graph,
--  Editor.Ada_Expected_Call_Filters.Build_With_Type_Graph, and
--  Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility_Pass957 must remain
--  present as the declaration-derived type-graph compatibility bridge for
--  expected-call filtering.  The model must stay parser/snapshot-owned and must
--  not introduce compiler invocation, LSP integration, renderer-side parsing,
--  background scans, file mutation, or dirty-state mutation.

--  Pass959 guard marker: Editor.Ada_Implicit_Conversions and
--  Test_Ada_Implicit_Conversion_Filter_Foundation_Pass959 must remain present
--  as the implicit-conversion classification layer after subtype/type-graph
--  compatibility.  The model must stay parser/snapshot-owned and must not
--  introduce compiler invocation, LSP integration, renderer-side parsing,
--  background scans, file mutation, or dirty-state mutation.
--  Pass960 guard marker: Editor.Ada_Static_Expressions and
--  Test_Ada_Static_Expression_Foundation_Pass960 must remain present to keep
--  compiler-grade static-expression staging covered by release validation.
--  Pass966 guard marker: Editor.Ada_Generic_Contracts and
--  Test_Ada_Generic_Contract_Foundation_Pass966 must remain present as the
--  generic contract staging foundation for formal declarations and
--  instantiation actual shape metadata.  The model must remain snapshot-owned
--  and must not introduce compiler invocation, LSP integration,
--  renderer-side parsing, background scans, file mutation, or dirty-state
--  mutation.
