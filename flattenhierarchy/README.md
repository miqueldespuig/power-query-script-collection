# Flatten Hierarchies About

**Hierarchies are everywhere**, they can represent a *bill of materials, company relationships, company structure, geographic zones, product categorization, etc.* And are a natural way to aggregate detailed information before going deep into details.

Hierarchies are usually represented in tabular form in either a *four column table*, or a *three column table* in transactional systems. Being the **3 column table** the **canonical way** to represent them.

When building reports based on a Star Schema a common way to handle a these relationships is using a technique called *flattening* which converts this 3 column table in a set of columns ready to be added to the dimension table and use them as grouping columns to look-up or look-down across the hierarchy.

These two functions are meant que speed things up as soon as you find a hierarchy.

## Four vs. Three column hierarchy table

The **4 column hierarchy** table:
* Has a line for each relationship in the hierarchy.
* Root nodes don't get their own line.
* The *parent name* column is needed because we need a way to name root nodes.

The **3 column hierarchy** table:
* Has a line for each node in the hierarchy.
* Root nodes get their own line.
* Root nodes will have either *null* or *blank* values in their ParentKey column.

# Functions

## fx4to3.pq

> Converts a 4 column hierarchy into a 3 column hierarchy.

Variables:
* **SourceTable** as *table*, A table with four columns that represent a hiearchy.
* **NodeKey** as *text*, A text with the *name of the column* which holds node key values.
* **NodeName** as *text*, A text with the *name of the column* which holds node name values.
* **ParentKey** as *text*, A text with the *name of the column* which holds parent key values.
* **ParentName** as *text*, A text with the *name of the column* which holds parent name values.

Returns:
* A table with the 4 column hiearchy converted to a 3 column hierarchy.

## fxFlatten.pq

> Flattens from rows in a 3 column hierarchy to as many columns as levels present.

Variables:
* **HierarchyTable** as *table*, A table with three columns that represent a hierarchy.
* **NodeKey** as *text*, A text with the *name of the column* which holds node key values.
* **NodeName** as *text*, A text with the *name of the column* which holds de node name values.
* **ParentKey** as *text*, A text with the *name of the column* which holds parent key values.

Returns: 
A table with the columns:
* **Node_ID**, Hierarchy nodes ID column.
* **Node_Name**, Hierarchy nodes name column.
* **NodeKey_### (*n)**, As many columns as levels are in the hierarchy, holding the key value for the parent node that corresponds to the ### level in the current node path. Each column is named after the depth level with zero left padded number up to three numbers.
* **NodeName_### (*n)**, The same as *NodeKey_###* but instead of key values holds name values.
* **NodeDepth**, *Integer* indicating the depth level of the current node.
* **Path**, *Text* string representing the path from the root node to the current node.
* **IsLeaf**, *Boolean* value indicating if the current node is at the end of the hierarchy.

# How To Use

Work in progress

# Disclaimer