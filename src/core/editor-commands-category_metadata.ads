with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Descriptors;

package Editor.Commands.Category_Metadata is

   function Category
     (Id : Command_Id) return Editor.Commands.Descriptors.Command_Category;

   function Category_Label
     (Category : Editor.Commands.Descriptors.Command_Category) return String;

   function Discoverability_Category_Label
     (Id : Command_Id) return String;

   function Classification_Label
     (Id : Command_Id) return String;

   function Surface_Relevance_Label
     (Id : Command_Id) return String;

   function Guard_Label
     (Id : Command_Id) return String;

end Editor.Commands.Category_Metadata;
