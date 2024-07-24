-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 24, 2024 at 12:18 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `migacoan`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `ShowAllPesanan` ()   BEGIN
    SELECT * FROM Pesanan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateStatusLogPesanan` (`p_log_id` INT, `p_status_baru` VARCHAR(50))   BEGIN
    DECLARE current_status VARCHAR(50);

    -- Mengambil status saat ini berdasarkan log_id
    SELECT status INTO current_status 
    FROM LogPesanan 
    WHERE log_id = p_log_id
    LIMIT 1;

    -- Memeriksa status saat ini dan mengubah ke status berikutnya jika sesuai
    IF current_status = 'Pesanan baru' AND p_status_baru = 'Pesanan diproses' THEN
        UPDATE LogPesanan 
        SET status = p_status_baru 
        WHERE log_id = p_log_id;
    ELSEIF current_status = 'Pesanan diproses' AND p_status_baru = 'Pesanan siap dibawa' THEN
        UPDATE LogPesanan 
        SET status = p_status_baru 
        WHERE log_id = p_log_id;
    ELSEIF current_status = 'Pesanan siap dibawa' AND p_status_baru = 'Pesanan selesai' THEN
        UPDATE LogPesanan 
        SET status = p_status_baru 
        WHERE log_id = p_log_id;
    ELSEIF current_status = 'Pesanan selesai' AND p_status_baru = 'Pesanan selesai' THEN
        DELETE FROM LogPesanan 
        WHERE log_id = p_log_id;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Status tidak valid atau urutan status salah.';
    END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `TotalPenjualan` () RETURNS INT(11)  BEGIN
    	DECLARE total INT;
    	SELECT SUM(total_harga) INTO total FROM Pesanan;
    	RETURN total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `TotalPesananPelanggan` (`pelanggan` INT, `bulan` INT) RETURNS INT(11)  BEGIN
    DECLARE total INT;
    SELECT SUM(total_harga) INTO total FROM Pesanan
    WHERE pelanggan_id = pelanggan AND MONTH(tgl_pesanan) = bulan;
    RETURN total;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `base_view_karyawan`
-- (See below for the actual view)
--
CREATE TABLE `base_view_karyawan` (
`karyawan_id` int(11)
,`nama_karyawan` varchar(50)
,`pesanan_id` int(11)
,`tugas` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `detailpesanan`
--

CREATE TABLE `detailpesanan` (
  `detail_id` int(11) NOT NULL,
  `pesanan_id` int(11) DEFAULT NULL,
  `menu_id` int(11) DEFAULT NULL,
  `jumlah` int(11) DEFAULT NULL,
  `harga` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `detailpesanan`
--

INSERT INTO `detailpesanan` (`detail_id`, `pesanan_id`, `menu_id`, `jumlah`, `harga`) VALUES
(1, 1, 1, 5, 85000),
(2, 1, 3, 2, 9000),
(3, 2, 2, 2, 32000),
(4, 3, 4, 1, 9000),
(5, 4, 5, 2, 26000),
(6, 5, 1, 1, 15000),
(7, 5, 2, 1, 16000),
(8, 5, 1, 1, 16000),
(10, 4, 5, 2, 26000),
(11, 3, 4, 4, 27000),
(22, 2, 4, 2, 10000),
(23, 6, 4, 1, 32000);

--
-- Triggers `detailpesanan`
--
DELIMITER $$
CREATE TRIGGER `after_delete_detailpesanan` AFTER DELETE ON `detailpesanan` FOR EACH ROW BEGIN
  DECLARE old_amount DECIMAL(10,2);
  DECLARE new_total_harga DECIMAL(10,2);

  SET old_amount = OLD.harga * OLD.jumlah;

  SET new_total_harga = (SELECT total_harga FROM pesanan WHERE pesanan_id = OLD.pesanan_id) - old_amount;

  UPDATE pesanan
  SET total_harga = new_total_harga
  WHERE pesanan_id = OLD.pesanan_id;

  INSERT INTO log_trigger (action_type, table_name, old_values, new_values)
  VALUES ('DELETE', 'detailpesanan', CONCAT('detail_id: ', OLD.detail_id, ', pesanan_id: ', OLD.pesanan_id, ', menu_id: ', OLD.menu_id, ', jumlah: ', OLD.jumlah, ', harga: ', OLD.harga), NULL);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_insert_detailpesanan` AFTER INSERT ON `detailpesanan` FOR EACH ROW BEGIN
  DECLARE added_amount DECIMAL(10,2);

  SET added_amount = NEW.harga * NEW.jumlah;


  UPDATE pesanan
  SET total_harga = total_harga + added_amount
  WHERE pesanan_id = NEW.pesanan_id;


  INSERT INTO log_trigger (action_type, table_name, old_values, new_values)
  VALUES ('INSERT', 'detailpesanan', NULL, CONCAT('detail_id: ', NEW.detail_id, ', pesanan_id: ', NEW.pesanan_id, ', menu_id: ', NEW.menu_id, ', jumlah: ', NEW.jumlah, ', harga: ', NEW.harga));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_update_detailpesanan` AFTER UPDATE ON `detailpesanan` FOR EACH ROW BEGIN
  DECLARE new_total_harga DECIMAL(10,2);
  DECLARE added_amount DECIMAL(10,2);
  DECLARE old_amount DECIMAL(10,2);

  SET added_amount = NEW.harga * NEW.jumlah;
  SET old_amount = OLD.harga * OLD.jumlah;

  SET new_total_harga = (SELECT total_harga FROM pesanan WHERE pesanan_id = NEW.pesanan_id) - old_amount + added_amount;

  UPDATE pesanan
  SET total_harga = new_total_harga
  WHERE pesanan_id = NEW.pesanan_id;

  INSERT INTO log_trigger (action_type, table_name, old_values, new_values)
  VALUES (
    'UPDATE', 
    'detailpesanan', 
    CONCAT('detail_id: ', OLD.detail_id, ', pesanan_id: ', OLD.pesanan_id, ', menu_id: ', OLD.menu_id, ', jumlah: ', OLD.jumlah, ', harga: ', OLD.harga), 
    CONCAT('detail_id: ', NEW.detail_id, ', pesanan_id: ', NEW.pesanan_id, ', menu_id: ', NEW.menu_id, ', jumlah: ', NEW.jumlah, ', harga: ', NEW.harga)
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_delete_detailpesanan` BEFORE DELETE ON `detailpesanan` FOR EACH ROW BEGIN
  -- Validasi harga sebelum penghapusan
  IF OLD.harga < 10000 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tidak dapat menghapus pesanan di bawah 10000';
  END IF;

  -- Mencatat tindakan penghapusan ke log_trigger
  INSERT INTO log_trigger (action_type, table_name, old_values, new_values)
  VALUES ('DELETE', 'detailpesanan', CONCAT('detail_id: ', OLD.detail_id, ', pesanan_id: ', OLD.pesanan_id, ', menu_id: ', OLD.menu_id, ', jumlah: ', OLD.jumlah, ', harga: ', OLD.harga), NULL);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_insert_detailpesanan` BEFORE INSERT ON `detailpesanan` FOR EACH ROW BEGIN
  IF NEW.harga < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Harga tidak boleh negatif!';
  END IF;

  INSERT INTO log_trigger (action_type, table_name, old_values, new_values)
  VALUES ('INSERT', 'detailpesanan', NULL, CONCAT('detail_id: ', NEW.detail_id, ', pesanan_id: ', NEW.pesanan_id, ', menu_id: ', NEW.menu_id, ', jumlah: ', NEW.jumlah, ', harga: ', NEW.harga));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_update_detailpesanan` BEFORE UPDATE ON `detailpesanan` FOR EACH ROW BEGIN
  IF NEW.jumlah > 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah tidak boleh lebih dari 10!';
  END IF;

  INSERT INTO log_trigger (action_type, table_name, old_values, new_values)
  VALUES ('UPDATE', 'detailpesanan', CONCAT('detail_id: ', OLD.detail_id, ', pesanan_id: ', OLD.pesanan_id, ', menu_id: ', OLD.menu_id, ', jumlah: ', OLD.jumlah, ', harga: ', OLD.harga), CONCAT('detail_id: ', NEW.detail_id, ', pesanan_id: ', NEW.pesanan_id, ', menu_id: ', NEW.menu_id, ', jumlah: ', NEW.jumlah, ', harga: ', NEW.harga));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `horizontal_view_karyawan`
-- (See below for the actual view)
--
CREATE TABLE `horizontal_view_karyawan` (
`karyawan_id` int(11)
,`nama_karyawan` varchar(50)
,`pesanan_id` int(11)
,`tugas` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inside_view_cascaded_karyawan`
-- (See below for the actual view)
--
CREATE TABLE `inside_view_cascaded_karyawan` (
`karyawan_id` int(11)
,`nama_karyawan` varchar(50)
,`pesanan_id` int(11)
,`tugas` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inside_view_local_karyawan`
-- (See below for the actual view)
--
CREATE TABLE `inside_view_local_karyawan` (
`karyawan_id` int(11)
,`nama_karyawan` varchar(50)
,`pesanan_id` int(11)
,`tugas` varchar(50)
);

-- --------------------------------------------------------

--
-- Table structure for table `karyawan`
--

CREATE TABLE `karyawan` (
  `karyawan_id` int(11) NOT NULL,
  `nama_karyawan` varchar(50) DEFAULT NULL,
  `pesanan_id` int(11) DEFAULT NULL,
  `tugas` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `karyawan`
--

INSERT INTO `karyawan` (`karyawan_id`, `nama_karyawan`, `pesanan_id`, `tugas`) VALUES
(1, 'John Doe', 1, 'Memasak pesanan'),
(2, 'Jane Smith', 2, 'Mempersiapkan pesanan'),
(3, 'Mike Johnson', 3, 'Memasak pesanan'),
(4, 'Emily Davis', 4, 'Membungkus pesanan'),
(5, 'David Brown', 5, 'Melayani pelanggan'),
(6, 'Sarah Williams', 6, 'Mengantar pesanan'),
(7, 'Chris Martinez', 7, 'Mempersiapkan pesanan'),
(8, 'Jessica Wilson', 8, 'Memasak pesanan'),
(9, 'Matthew Anderson', 9, 'Membungkus pesanan'),
(10, 'Daniel Thomas', 10, 'Melayani pelanggan'),
(31, 'Rina', 2, 'Membungkus pesanan'),
(32, 'Sinta', 4, 'Mempersiapkan pesanan');

-- --------------------------------------------------------

--
-- Table structure for table `logpesanan`
--

CREATE TABLE `logpesanan` (
  `log_id` int(11) NOT NULL,
  `pesanan_id` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `waktu` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `logpesanan`
--

INSERT INTO `logpesanan` (`log_id`, `pesanan_id`, `status`, `waktu`) VALUES
(1, 1, 'Pesanan Diproses', '2024-07-23 03:34:08'),
(2, 2, 'Pesanan diproses', '2024-07-23 03:34:08'),
(3, 3, 'Pesanan baru', '2024-07-23 03:34:08'),
(4, 4, 'Pesanan siap dibawa', '2024-07-23 03:34:08'),
(5, 5, 'Pesanan selesai', '2024-07-23 03:34:08');

-- --------------------------------------------------------

--
-- Table structure for table `log_trigger`
--

CREATE TABLE `log_trigger` (
  `log_id` int(11) NOT NULL,
  `action_type` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `table_name` varchar(50) NOT NULL,
  `old_values` text DEFAULT NULL,
  `new_values` text DEFAULT NULL,
  `action_time` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `log_trigger`
--

INSERT INTO `log_trigger` (`log_id`, `action_type`, `table_name`, `old_values`, `new_values`, `action_time`) VALUES
(1, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 1, menu_id: 4, jumlah: 1, harga: 80000', '2024-07-24 03:06:08'),
(2, 'INSERT', 'detailpesanan', NULL, 'detail_id: 14, pesanan_id: 1, menu_id: 4, jumlah: 1, harga: 80000', '2024-07-24 03:06:08'),
(3, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', '2024-07-24 03:09:09'),
(4, 'INSERT', 'detailpesanan', NULL, 'detail_id: 15, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', '2024-07-24 03:09:09'),
(5, 'DELETE', 'detailpesanan', 'detail_id: 14, pesanan_id: 1, menu_id: 4, jumlah: 1, harga: 80000', NULL, '2024-07-24 03:14:44'),
(6, 'DELETE', 'detailpesanan', 'detail_id: 15, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', NULL, '2024-07-24 03:14:49'),
(10, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', '2024-07-24 03:17:39'),
(11, 'INSERT', 'detailpesanan', NULL, 'detail_id: 19, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', '2024-07-24 03:17:39'),
(12, 'DELETE', 'detailpesanan', 'detail_id: 19, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', NULL, '2024-07-24 04:30:24'),
(13, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', '2024-07-24 04:30:27'),
(14, 'INSERT', 'detailpesanan', NULL, 'detail_id: 20, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', '2024-07-24 04:30:27'),
(15, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 2, menu_id: 4, jumlah: 2, harga: 10000', '2024-07-24 04:30:47'),
(16, 'INSERT', 'detailpesanan', NULL, 'detail_id: 21, pesanan_id: 2, menu_id: 4, jumlah: 2, harga: 10000', '2024-07-24 04:30:47'),
(17, 'DELETE', 'detailpesanan', 'detail_id: 20, pesanan_id: 2, menu_id: 4, jumlah: 1, harga: 10000', NULL, '2024-07-24 04:34:07'),
(18, 'DELETE', 'detailpesanan', 'detail_id: 21, pesanan_id: 2, menu_id: 4, jumlah: 2, harga: 10000', NULL, '2024-07-24 04:34:13'),
(19, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 2, menu_id: 4, jumlah: 2, harga: 10000', '2024-07-24 04:37:50'),
(20, 'INSERT', 'detailpesanan', NULL, 'detail_id: 22, pesanan_id: 2, menu_id: 4, jumlah: 2, harga: 10000', '2024-07-24 04:37:50'),
(21, 'UPDATE', 'detailpesanan', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 1, harga: 8000', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 1, harga: 9000', '2024-07-24 04:57:34'),
(22, 'UPDATE', 'detailpesanan', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 1, harga: 8000', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 1, harga: 9000', '2024-07-24 04:57:34'),
(23, 'UPDATE', 'detailpesanan', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 1, harga: 9000', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 2, harga: 9000', '2024-07-24 05:00:10'),
(24, 'UPDATE', 'detailpesanan', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 1, harga: 9000', 'detail_id: 2, pesanan_id: 1, menu_id: 3, jumlah: 2, harga: 9000', '2024-07-24 05:00:10'),
(25, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 6, menu_id: 4, jumlah: 1, harga: 32000', '2024-07-24 05:22:30'),
(26, 'INSERT', 'detailpesanan', NULL, 'detail_id: 23, pesanan_id: 6, menu_id: 4, jumlah: 1, harga: 32000', '2024-07-24 05:22:30'),
(27, 'INSERT', 'detailpesanan', NULL, 'detail_id: 0, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 8000', '2024-07-24 05:23:29'),
(28, 'INSERT', 'detailpesanan', NULL, 'detail_id: 24, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 8000', '2024-07-24 05:23:29'),
(29, 'UPDATE', 'detailpesanan', 'detail_id: 24, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 8000', 'detail_id: 24, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 10000', '2024-07-24 05:25:23'),
(30, 'UPDATE', 'detailpesanan', 'detail_id: 24, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 8000', 'detail_id: 24, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 10000', '2024-07-24 05:25:23'),
(31, 'DELETE', 'detailpesanan', 'detail_id: 24, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 10000', NULL, '2024-07-24 05:25:40'),
(32, 'DELETE', 'detailpesanan', 'detail_id: 24, pesanan_id: 6, menu_id: 3, jumlah: 2, harga: 10000', NULL, '2024-07-24 05:25:40'),
(33, 'INSERT', 'detailpesanan', NULL, 'detail_id: 24, pesanan_id: 6, menu_id: 2, jumlah: 1, harga: 17000', '2024-07-24 05:34:00'),
(34, 'INSERT', 'detailpesanan', NULL, 'detail_id: 24, pesanan_id: 6, menu_id: 2, jumlah: 1, harga: 17000', '2024-07-24 05:34:00'),
(35, 'DELETE', 'detailpesanan', 'detail_id: 24, pesanan_id: 6, menu_id: 2, jumlah: 1, harga: 17000', NULL, '2024-07-24 05:34:42'),
(36, 'DELETE', 'detailpesanan', 'detail_id: 24, pesanan_id: 6, menu_id: 2, jumlah: 1, harga: 17000', NULL, '2024-07-24 05:34:42');

-- --------------------------------------------------------

--
-- Table structure for table `menu`
--

CREATE TABLE `menu` (
  `menu_id` int(11) NOT NULL,
  `nama_menu` varchar(50) DEFAULT NULL,
  `harga` int(11) DEFAULT NULL,
  `kategori` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `menu`
--

INSERT INTO `menu` (`menu_id`, `nama_menu`, `harga`, `kategori`) VALUES
(1, 'Mie Gacoan', 17000, 'Makanan'),
(2, 'Mie Hompimpa', 17000, 'Makanan'),
(3, 'Es Teh', 8000, 'Minuman'),
(4, 'Es Matcha', 9000, 'Minuman'),
(5, 'Pangsit Goreng', 14000, 'Makanan');

-- --------------------------------------------------------

--
-- Table structure for table `pelanggan`
--

CREATE TABLE `pelanggan` (
  `pelanggan_id` int(11) NOT NULL,
  `nama_pelanggan` varchar(50) DEFAULT NULL,
  `alamat` varchar(100) DEFAULT NULL,
  `no_telepon` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pelanggan`
--

INSERT INTO `pelanggan` (`pelanggan_id`, `nama_pelanggan`, `alamat`, `no_telepon`) VALUES
(1, 'Andi', 'Jl. Merdeka No.1', '081234567890'),
(2, 'Budi', 'Jl. Soekarno No.2', '082345678901'),
(3, 'Cici', 'Jl. Hatta No.3', '083456789012'),
(4, 'Doni', 'Jl. Sudirman No.4', '084567890123'),
(5, 'Eka', 'Jl. Thamrin No.5', '085678901234');

-- --------------------------------------------------------

--
-- Table structure for table `pesanan`
--

CREATE TABLE `pesanan` (
  `pesanan_id` int(11) NOT NULL,
  `pelanggan_id` int(11) DEFAULT NULL,
  `tgl_pesanan` date DEFAULT NULL,
  `total_harga` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pesanan`
--

INSERT INTO `pesanan` (`pesanan_id`, `pelanggan_id`, `tgl_pesanan`, `total_harga`) VALUES
(1, 1, '2023-07-20', 103000),
(2, 2, '2023-07-21', 62000),
(3, 3, '2023-07-22', 36000),
(4, 4, '2023-07-23', 52000),
(5, 5, '2023-07-24', 47000),
(6, 4, '2024-07-24', 32000),
(7, 4, '2024-07-24', 42000),
(8, 3, '2024-07-22', 17000),
(9, 1, '2024-07-23', 32000),
(10, 5, '2024-07-22', 34000);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vertical_view_karyawan`
-- (See below for the actual view)
--
CREATE TABLE `vertical_view_karyawan` (
`karyawan_id` int(11)
,`nama_karyawan` varchar(50)
,`tugas` varchar(50)
);

-- --------------------------------------------------------

--
-- Structure for view `base_view_karyawan`
--
DROP TABLE IF EXISTS `base_view_karyawan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `base_view_karyawan`  AS SELECT `karyawan`.`karyawan_id` AS `karyawan_id`, `karyawan`.`nama_karyawan` AS `nama_karyawan`, `karyawan`.`pesanan_id` AS `pesanan_id`, `karyawan`.`tugas` AS `tugas` FROM `karyawan` WHERE `karyawan`.`tugas` in ('Membungkus pesanan','Mempersiapkan pesanan') ;

-- --------------------------------------------------------

--
-- Structure for view `horizontal_view_karyawan`
--
DROP TABLE IF EXISTS `horizontal_view_karyawan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `horizontal_view_karyawan`  AS SELECT `karyawan`.`karyawan_id` AS `karyawan_id`, `karyawan`.`nama_karyawan` AS `nama_karyawan`, `karyawan`.`pesanan_id` AS `pesanan_id`, `karyawan`.`tugas` AS `tugas` FROM `karyawan` WHERE `karyawan`.`tugas` = 'Memasak Pesanan' ;

-- --------------------------------------------------------

--
-- Structure for view `inside_view_cascaded_karyawan`
--
DROP TABLE IF EXISTS `inside_view_cascaded_karyawan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inside_view_cascaded_karyawan`  AS SELECT `base_view_karyawan`.`karyawan_id` AS `karyawan_id`, `base_view_karyawan`.`nama_karyawan` AS `nama_karyawan`, `base_view_karyawan`.`pesanan_id` AS `pesanan_id`, `base_view_karyawan`.`tugas` AS `tugas` FROM `base_view_karyawan` WHERE `base_view_karyawan`.`pesanan_id` is not null WITH CASCADED CHECK OPTION  ;

-- --------------------------------------------------------

--
-- Structure for view `inside_view_local_karyawan`
--
DROP TABLE IF EXISTS `inside_view_local_karyawan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inside_view_local_karyawan`  AS SELECT `base_view_karyawan`.`karyawan_id` AS `karyawan_id`, `base_view_karyawan`.`nama_karyawan` AS `nama_karyawan`, `base_view_karyawan`.`pesanan_id` AS `pesanan_id`, `base_view_karyawan`.`tugas` AS `tugas` FROM `base_view_karyawan` WHERE `base_view_karyawan`.`pesanan_id` is not null WITH LOCAL CHECK OPTION  ;

-- --------------------------------------------------------

--
-- Structure for view `vertical_view_karyawan`
--
DROP TABLE IF EXISTS `vertical_view_karyawan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vertical_view_karyawan`  AS SELECT `karyawan`.`karyawan_id` AS `karyawan_id`, `karyawan`.`nama_karyawan` AS `nama_karyawan`, `karyawan`.`tugas` AS `tugas` FROM `karyawan` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `detailpesanan`
--
ALTER TABLE `detailpesanan`
  ADD PRIMARY KEY (`detail_id`),
  ADD KEY `pesanan_id` (`pesanan_id`),
  ADD KEY `menu_id` (`menu_id`);

--
-- Indexes for table `karyawan`
--
ALTER TABLE `karyawan`
  ADD PRIMARY KEY (`karyawan_id`),
  ADD KEY `pesanan_id` (`pesanan_id`),
  ADD KEY `nama_karyawan` (`nama_karyawan`);

--
-- Indexes for table `logpesanan`
--
ALTER TABLE `logpesanan`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `pesanan_id` (`pesanan_id`) USING BTREE;

--
-- Indexes for table `log_trigger`
--
ALTER TABLE `log_trigger`
  ADD PRIMARY KEY (`log_id`);

--
-- Indexes for table `menu`
--
ALTER TABLE `menu`
  ADD PRIMARY KEY (`menu_id`),
  ADD KEY `idx_nama_harga` (`nama_menu`,`harga`);

--
-- Indexes for table `pelanggan`
--
ALTER TABLE `pelanggan`
  ADD PRIMARY KEY (`pelanggan_id`),
  ADD KEY `idx_nama_pelanggan` (`nama_pelanggan`,`alamat`);

--
-- Indexes for table `pesanan`
--
ALTER TABLE `pesanan`
  ADD PRIMARY KEY (`pesanan_id`),
  ADD KEY `pelanggan_id` (`pelanggan_id`) USING BTREE;

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `detailpesanan`
--
ALTER TABLE `detailpesanan`
  MODIFY `detail_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `karyawan`
--
ALTER TABLE `karyawan`
  MODIFY `karyawan_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `log_trigger`
--
ALTER TABLE `log_trigger`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `menu`
--
ALTER TABLE `menu`
  MODIFY `menu_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `pelanggan`
--
ALTER TABLE `pelanggan`
  MODIFY `pelanggan_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `pesanan`
--
ALTER TABLE `pesanan`
  MODIFY `pesanan_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `detailpesanan`
--
ALTER TABLE `detailpesanan`
  ADD CONSTRAINT `detailpesanan_ibfk_1` FOREIGN KEY (`pesanan_id`) REFERENCES `pesanan` (`pesanan_id`),
  ADD CONSTRAINT `detailpesanan_ibfk_2` FOREIGN KEY (`menu_id`) REFERENCES `menu` (`menu_id`);

--
-- Constraints for table `karyawan`
--
ALTER TABLE `karyawan`
  ADD CONSTRAINT `karyawan_ibfk_1` FOREIGN KEY (`pesanan_id`) REFERENCES `pesanan` (`pesanan_id`);

--
-- Constraints for table `logpesanan`
--
ALTER TABLE `logpesanan`
  ADD CONSTRAINT `logpesanan_ibfk_1` FOREIGN KEY (`pesanan_id`) REFERENCES `pesanan` (`pesanan_id`);

--
-- Constraints for table `pesanan`
--
ALTER TABLE `pesanan`
  ADD CONSTRAINT `pesanan_ibfk_1` FOREIGN KEY (`pelanggan_id`) REFERENCES `pelanggan` (`pelanggan_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
