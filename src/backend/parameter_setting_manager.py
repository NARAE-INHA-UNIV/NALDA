from PySide6.QtCore import QAbstractItemModel, QModelIndex, Qt, QObject, Slot


data = [
    {
        "name": "Documents",
        "value": 0,
        "visible": False,
        "children": [
            {
                "name": "Projects",
                "value": 8,
                "visible": False,
                "children": [
                    {"name": "Project A", "value": 15, "visible": True, "children": []},
                    {"name": "Project B", "value": 12, "visible": True, "children": []},
                    {"name": "Project C", "value": 8, "visible": True, "children": []},
                ],
            },
            {"name": "report.pdf", "value": 3, "visible": True, "children": []},
            {"name": "notes.txt", "value": 7, "visible": True, "children": []},
        ],
    },
    {
        "name": "Pictures",
        "value": 25,
        "visible": False,
        "children": [
            {"name": "photo1.jpg", "value": 15, "visible": True, "children": []},
            {"name": "photo2.png", "value": 10, "visible": True, "children": []},
            {
                "name": "Vacation",
                "value": 20,
                "visible": False,
                "children": [
                    {"name": "Hawaii 2023", "value": 18, "visible": True, "children": []},
                    {"name": "Europe 2022", "value": 22, "visible": True, "children": []},
                ],
            },
        ],
    },
    {
        "name": "Music",
        "value": 5,
        "visible": False,
        "children": [
            {
                "name": "Albums",
                "value": 3,
                "visible": False,
                "children": [
                    {"name": "Rock Collection", "value": 5, "visible": True, "children": []},
                    {"name": "Jazz Classics", "value": 8, "visible": True, "children": []},
                ],
            },
            {"name": "song1.mp3", "value": 2, "visible": True, "children": []},
        ],
    }
]


class TreeItem:
    _id_counter = 0

    def __init__(self, name: str, value: int = 0, visible: bool = False, parent=None):
        TreeItem._id_counter += 1
        self.item_id = TreeItem._id_counter
        self.name = name
        self.value = value
        self.visible = visible
        self.parent_item = parent
        self.children = []

    def add_child(self, child):
        child.parent_item = self
        self.children.append(child)

    def child_count(self):
        return len(self.children)

    def child(self, row):
        if 0 <= row < len(self.children):
            return self.children[row]
        return None

    def row(self):
        if self.parent_item:
            return self.parent_item.children.index(self)
        return 0


class SimpleTreeModel(QAbstractItemModel):

    def __init__(self, parent=None):
        super().__init__(parent)
        self.root_item = TreeItem("Root")
        self.items_by_id = {}  # ID로 아이템을 찾기 위한 딕셔너리
        self._setup_model_data()

    def _setup_model_data(self):
        for item in data:
            self.root_item.add_child(self._make_tree_item(item, parent=self.root_item))

    def _make_tree_item(self, item, parent):
        """Recursively create TreeItem from dictionary data"""
        new_item = TreeItem(item['name'], item['value'], item['visible'], parent=parent)
        self.items_by_id[new_item.item_id] = new_item  # ID로 아이템 등록
        for child in item['children']:
            new_item.add_child(self._make_tree_item(child, parent=new_item))
        return new_item

    def index(self, row, column, parent=QModelIndex()):
        if not self.hasIndex(row, column, parent):
            return QModelIndex()

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = parent.internalPointer()

        child_item = parent_item.child(row)
        if child_item:
            return self.createIndex(row, column, child_item)
        return QModelIndex()

    def parent(self, index):
        if not index.isValid():
            return QModelIndex()

        child_item = index.internalPointer()
        parent_item = child_item.parent_item

        if parent_item == self.root_item or parent_item is None:
            return QModelIndex()

        return self.createIndex(parent_item.row(), 0, parent_item)

    def rowCount(self, parent=QModelIndex()):
        if parent.column() > 0:
            return 0

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = parent.internalPointer()

        return parent_item.child_count()

    def columnCount(self, parent=QModelIndex()):
        return 1

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None

        item = index.internalPointer()

        if role == Qt.DisplayRole:
            print(item.name, item.value, item.item_id)
            return {
                'name': item.name,
                'value': item.value,
                'visible': item.visible,
                'itemId': item.item_id
            }
        elif role == Qt.EditRole:
            return item.value  # 값 편집용
        elif role == Qt.UserRole:  # 커스텀 역할로 ID 반환
            return item.item_id

        return None

    def setData(self, index, value, role=Qt.EditRole):
        """Set data at the given index"""
        print("setData called with index:", index, "value:", value, "role:", role)
        if not index.isValid():
            print("Invalid index in setData()")
            return False

        item = index.internalPointer()

        if role == Qt.EditRole:
            # 값을 설정 (정수로 변환)
            try:
                item.value = int(value)
                # 데이터가 변경되었음을 알림
                self.dataChanged.emit(index, index, [role])
                print("Value set to:", item.value)
                return True
            except (ValueError, TypeError):
                return False

        return False

    def flags(self, index):
        """Return the item flags for the given index"""
        if not index.isValid():
            return Qt.NoItemFlags

        return Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsEditable

    @Slot(int, int)
    def updateValueById(self, item_id, new_value):
        """ID로 아이템을 찾아서 값을 업데이트"""
        if item_id in self.items_by_id:
            item = self.items_by_id[item_id]
            item.value = new_value

            # 해당 아이템의 인덱스를 찾아서 dataChanged 시그널 발생
            index = self._find_index_by_item(item)
            if index.isValid():
                self.dataChanged.emit(index, index, [Qt.EditRole])
                print(f"Updated item {item.name} (ID: {item_id}) to value: {new_value}")
                return True
        return False

    @Slot(int, result=int)
    def getValueById(self, item_id):
        """ID로 아이템을 찾아서 값을 반환"""
        if item_id in self.items_by_id:
            item = self.items_by_id[item_id]
            return item.value
        return None

    def _find_index_by_item(self, target_item):
        """TreeItem을 받아서 해당하는 QModelIndex를 반환"""
        def search_recursive(parent_index, parent_item):
            for row in range(parent_item.child_count()):
                child_item = parent_item.child(row)
                if child_item == target_item:
                    return self.index(row, 0, parent_index)

                child_index = self.index(row, 0, parent_index)
                result = search_recursive(child_index, child_item)
                if result.isValid():
                    return result

            return QModelIndex()

        return search_recursive(QModelIndex(), self.root_item)


class ParameterSettingManager(QObject):

    def __init__(self):
        super().__init__()
        self.tree_model = SimpleTreeModel()
